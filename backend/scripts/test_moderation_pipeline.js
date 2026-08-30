import dotenv from 'dotenv';
dotenv.config();

import sequelize from '../src/config/database.js';
import moderationService from '../src/services/moderationService.js';
import { User, ModerationRule, FlaggedContent, ActivityLog } from '../src/models/index.js';

async function runModerationPipelineTests() {
    console.log('===============================================================');
    console.log('🚀 RUNNING CONTENT MODERATION & PRIVACY ENGINE PIPELINE TESTS');
    console.log('===============================================================\n');

    try {
        await sequelize.authenticate();
        console.log('✅ PostgreSQL connected.');

        await sequelize.sync();
        await moderationService.seedDefaultRulesIfEmpty();
        moderationService.invalidateCache();
        console.log('✅ Moderation rules synced & cache primed.\n');

        let passed = 0;
        let total = 0;

        function assertTest(name, condition, details = '') {
            total++;
            if (condition) {
                console.log(`  ✅ [PASS] ${name}`);
                passed++;
            } else {
                console.error(`  ❌ [FAIL] ${name} -> ${details}`);
            }
        }

        console.log('--- TEST GROUP 1: LEGITIMATE PAYMENT METHODS (ZERO FALSE POSITIVES) ---');
        const paymentPhrases = [
            'Bank transfer accepted',
            'TNG accepted for this item',
            'Cash on delivery at library',
            'Payment method: bank transfer or Touch n Go',
            'Cash only please meet at safe zone',
            'Will pay you via online bank transfer after inspection'
        ];

        for (const phrase of paymentPhrases) {
            const res = await moderationService.evaluateContent(phrase);
            assertTest(
                `Allow legitimate payment phrase: "${phrase}"`,
                res.action === 'allow' && !res.isBlocked && !res.isFlagged,
                `Expected allow, got action=${res.action}, categories=${res.matchedCategories}`
            );
        }

        console.log('\n--- TEST GROUP 2: PROFANITY MASKING ---');
        const profanityRes = await moderationService.evaluateContent('This is a fuck bad item shit');
        assertTest(
            'Mask profanity with *** while allowing transmission',
            profanityRes.sanitizedText === 'This is a *** bad item ***' && profanityRes.action === 'mask',
            `Got sanitizedText="${profanityRes.sanitizedText}", action=${profanityRes.action}`
        );

        console.log('\n--- TEST GROUP 3: PRIVACY & PII DETECTION ---');
        const phoneRes = await moderationService.evaluateContent('Contact me at 012-3456789 tonight');
        assertTest(
            'Flag Malaysian mobile phone number leak',
            phoneRes.matchedCategories.includes('privacy') || phoneRes.matchedCategories.includes('off_platform_contact'),
            `Matched categories: ${phoneRes.matchedCategories}`
        );

        const emailRes = await moderationService.evaluateContent('Email me your resume at student123@gmail.com');
        assertTest(
            'Flag unencrypted email address leak',
            emailRes.matchedCategories.includes('privacy') && emailRes.isFlagged,
            `Matched categories: ${emailRes.matchedCategories}`
        );

        const icRes = await moderationService.evaluateContent('Here is my IC number 010203-14-5678 for verification');
        assertTest(
            'Block Malaysian NRIC / IC number transmission',
            icRes.isBlocked && icRes.action === 'block' && icRes.matchedCategories.includes('privacy'),
            `Expected block, got isBlocked=${icRes.isBlocked}, action=${icRes.action}`
        );

        console.log('\n--- TEST GROUP 4: CONTEXTUAL OFF-PLATFORM & SCAM SOLICITATION ---');
        const waContactRes = await moderationService.evaluateContent('WhatsApp me at 0198765432 for faster deal');
        assertTest(
            'Flag contextual WhatsApp solicitation with phone number',
            waContactRes.matchedCategories.includes('off_platform_contact') && waContactRes.isFlagged,
            `Matched categories: ${waContactRes.matchedCategories}`
        );

        const waLinkRes = await moderationService.evaluateContent('Click here wa.me/60123456789 to chat');
        assertTest(
            'Flag wa.me external redirection link',
            waLinkRes.matchedCategories.includes('off_platform_contact') && waLinkRes.isFlagged,
            `Matched categories: ${waLinkRes.matchedCategories}`
        );

        const waIsolatedRes = await moderationService.evaluateContent('Do you prefer Telegram or WhatsApp sticker packs?');
        assertTest(
            'Allow isolated app name discussion without contact intent',
            !waIsolatedRes.isBlocked,
            `Got action=${waIsolatedRes.action}`
        );

        console.log('\n--- TEST GROUP 5: RELIGIOUS / CULTURAL HARMONY & ABUSE SAFEGUARD ---');
        const religiousAcademicRes = await moderationService.evaluateContent('I am selling a textbook on Islamic History and Comparative Christianity.');
        assertTest(
            'Allow academic and respectful religious discussion without false positives',
            religiousAcademicRes.action === 'allow' && !religiousAcademicRes.isFlagged,
            `Expected allow, got action=${religiousAcademicRes.action}`
        );

        const religiousAbuseRes = await moderationService.evaluateContent('I will destroy Islam and burn churches');
        assertTest(
            'Flag hostile religious abuse / violence pattern',
            religiousAbuseRes.matchedCategories.includes('religious_sensitive') && religiousAbuseRes.isFlagged,
            `Matched categories: ${religiousAbuseRes.matchedCategories}`
        );

        console.log('\n--- TEST GROUP 6: PRIVACY-PRESERVED SNIPPET RECORDING ---');
        const testUser = await User.findOne();
        if (testUser) {
            const auditRes = await moderationService.evaluateContent('Hey whatsapp me at 012-99887766 right now', {
                userId: testUser.id,
                sourceType: 'message',
                sourceId: 'test-msg-1'
            });
            assertTest(
                'Evaluation triggered flagging and queued review',
                auditRes.isFlagged,
                `Expected flagged`
            );

            // Wait brief moment for async logging
            await new Promise(r => setTimeout(r, 200));

            const latestLog = await FlaggedContent.findOne({
                where: { user_id: testUser.id },
                order: [['createdAt', 'DESC']]
            });

            assertTest(
                'FlaggedContent snippet has numbers masked (e.g. 012-***) for privacy preservation',
                latestLog && latestLog.matched_snippet.includes('***') && !latestLog.matched_snippet.includes('99887766'),
                `Snippet stored: "${latestLog?.matched_snippet}"`
            );
        }

        console.log('\n===============================================================');
        console.log(`📊 TEST RESULTS: ${passed}/${total} TESTS PASSED (${((passed/total)*100).toFixed(1)}%)`);
        console.log('===============================================================\n');

        if (passed === total) {
            console.log('🎉 ALL MODERATION PIPELINE TESTS COMPLETED SUCCESSFULLY!');
        } else {
            console.error('⚠️ SOME TESTS FAILED. PLEASE INSPECT LOGS ABOVE.');
            process.exit(1);
        }

    } catch (err) {
        console.error('Test Execution Error:', err);
        process.exit(1);
    } finally {
        await sequelize.close();
    }
}

runModerationPipelineTests();
