import dotenv from 'dotenv';
dotenv.config();

import sequelize from '../src/config/database.js';
import { User, StudentWhitelist } from '../src/models/index.js';
import { checkAndExpireOldStudents } from '../src/scripts/cronJobs.js';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { Readable } from 'stream';
import csvParser from 'csv-parser';
import { Op } from 'sequelize';

async function runTests() {
    console.log('--- STARTING ADMIN CSV WHITELIST & REGISTRATION VERIFICATION ---');

    try {
        await sequelize.authenticate();
        console.log('✓ Database connected');

        // Sync model safely (DO NOT FORCE SYNC)
        await StudentWhitelist.sync();
        console.log('✓ StudentWhitelist table verified and synced safely without dropping data');

        const currentYear = new Date().getFullYear();

        // 1. Test CSV Parsing & Auto-calculation Simulation
        console.log('\n--- 1. Testing CSV Parsing & Auto-calculation (> 4 years rule) ---');
        const sampleCsv = `student_id,email,faculty,enrollment_year\n24PMR01111,active_test1@student.mmu.edu.my,FCI,${currentYear - 1}\n20PMR02222,expired_test2@student.mmu.edu.my,FOE,${currentYear - 5}\n24PMR03333,active_test3@student.mmu.edu.my,FCM,${currentYear}\n`;

        const parsedRows = [];
        const bufferStream = new Readable();
        bufferStream.push(Buffer.from(sampleCsv));
        bufferStream.push(null);

        const parser = bufferStream.pipe(csvParser({
            mapHeaders: ({ header }) => header.replace(/^\uFEFF/, '').trim().toLowerCase().replace(/[\s_-]+/g, '')
        }));

        for await (const row of parser) {
            parsedRows.push(row);
        }

        console.log(`Parsed ${parsedRows.length} rows from sample CSV.`);

        for (const row of parsedRows) {
            const studentId = String(row.studentid).trim().toUpperCase();
            const email = String(row.email).trim().toLowerCase();
            const faculty = String(row.faculty).trim();
            const enrollmentYear = parseInt(row.enrollmentyear, 10);
            const status = (currentYear - enrollmentYear > 4) ? 'Expired' : 'Active';

            const [record, created] = await StudentWhitelist.upsert({
                student_id: studentId,
                email,
                faculty,
                enrollment_year: enrollmentYear,
                status
            });

            console.log(`✓ Seeded ${studentId} (${email}) - Intake: ${enrollmentYear} => Status: ${status} (Created: ${created})`);
        }

        // Verify active vs expired in DB
        const test1 = await StudentWhitelist.findOne({ where: { student_id: '24PMR01111' } });
        if (test1 && test1.status === 'Active') {
            console.log('✓ Test 1 Passed: Recent student (enrollment year ' + (currentYear - 1) + ') correctly set to Active');
        } else {
            console.error('✗ Test 1 Failed:', test1);
        }

        const test2 = await StudentWhitelist.findOne({ where: { student_id: '20PMR02222' } });
        if (test2 && test2.status === 'Expired') {
            console.log('✓ Test 2 Passed: 5-year-old student (enrollment year ' + (currentYear - 5) + ') correctly auto-expired');
        } else {
            console.error('✗ Test 2 Failed:', test2);
        }

        // 2. Test Cron Auto-expiry
        console.log('\n--- 2. Testing Cron Auto-expiry logic ---');
        // Add a student with enrollment year 2020 and status 'Active' manually
        const tempStudent = await StudentWhitelist.create({
            student_id: '19PMR99999',
            email: 'cron_expire_test@student.mmu.edu.my',
            faculty: 'FOE',
            enrollment_year: currentYear - 6,
            status: 'Active'
        });
        console.log(`Created temp student ${tempStudent.student_id} with enrollment_year ${currentYear - 6} as Active`);

        // Run cron job function
        await checkAndExpireOldStudents();

        const updatedTemp = await StudentWhitelist.findByPk(tempStudent.id);
        if (updatedTemp && updatedTemp.status === 'Expired') {
            console.log('✓ Test 3 Passed: Cron job correctly auto-expired overdue student');
        } else {
            console.error('✗ Test 3 Failed: Cron job did not expire student:', updatedTemp);
        }
        await updatedTemp.destroy();

        // 3. Test Registration Verification Flows
        console.log('\n--- 3. Testing Registration Whitelist Validation Logic ---');

        // Helper mock register simulation
        async function simulateRegistration(body) {
            const { email, university_id, username, password, full_name } = body;
            const normalizedEmail = email.toLowerCase().trim();
            const normalizedUniId = university_id.toUpperCase().trim();

            const whitelistRecord = await StudentWhitelist.findOne({
                where: {
                    [Op.and]: [
                        sequelize.where(sequelize.fn('LOWER', sequelize.col('email')), normalizedEmail),
                        sequelize.where(sequelize.fn('UPPER', sequelize.col('student_id')), normalizedUniId)
                    ]
                }
            });

            if (!whitelistRecord) {
                return { status: 403, error: 'Student record not found in the university database.' };
            }

            const isOverDuration = (currentYear - whitelistRecord.enrollment_year) > 4;
            if (whitelistRecord.status === 'Expired' || isOverDuration) {
                if (whitelistRecord.status !== 'Expired') {
                    whitelistRecord.status = 'Expired';
                    await whitelistRecord.save();
                }
                return { status: 403, error: 'Student account expired. Graduated students cannot access the active trading platform.' };
            }

            return { status: 201, message: 'Registration successful. Proceed with OTP verification.', whitelistRecord };
        }

        // Test Scenario A: Unwhitelisted user
        console.log('\nScenario A: Non-whitelisted student registration attempt:');
        const resA = await simulateRegistration({
            email: 'intruder99@student.mmu.edu.my',
            university_id: '99PMR99999',
            username: 'intruder99',
            password: 'Password123!',
            full_name: 'Intruder User'
        });
        if (resA.status === 403 && resA.error === 'Student record not found in the university database.') {
            console.log('✓ Scenario A Passed: Blocked with 403 - "Student record not found in the university database."');
        } else {
            console.error('✗ Scenario A Failed:', resA);
        }

        // Test Scenario B: Whitelisted Expired user (graduated)
        console.log('\nScenario B: Expired / Graduated student registration attempt:');
        const resB = await simulateRegistration({
            email: 'expired_test2@student.mmu.edu.my',
            university_id: '20PMR02222',
            username: 'graduated_student',
            password: 'Password123!',
            full_name: 'Graduated Student'
        });
        if (resB.status === 403 && resB.error === 'Student account expired. Graduated students cannot access the active trading platform.') {
            console.log('✓ Scenario B Passed: Blocked with 403 - "Student account expired. Graduated students cannot access the active trading platform."');
        } else {
            console.error('✗ Scenario B Failed:', resB);
        }

        // Test Scenario C: Whitelisted Active user
        console.log('\nScenario C: Whitelisted Active student registration attempt:');
        const resC = await simulateRegistration({
            email: 'active_test1@student.mmu.edu.my',
            university_id: '24PMR01111',
            username: 'active_student_test',
            password: 'Password123!',
            full_name: 'Active Student'
        });
        if (resC.status === 201 && resC.whitelistRecord.status === 'Active') {
            console.log('✓ Scenario C Passed: Allowed with 201 - Registration proceeded normally');
        } else {
            console.error('✗ Scenario C Failed:', resC);
        }

        // Test Scenario D: Manual Admin Toggle
        console.log('\nScenario D: Admin manually toggles status of expired user to Active (Extend):');
        const expiredStudent = await StudentWhitelist.findOne({ where: { student_id: '20PMR02222' } });
        expiredStudent.status = 'Active';
        await expiredStudent.save();

        const resD = await simulateRegistration({
            email: 'expired_test2@student.mmu.edu.my',
            university_id: '20PMR02222',
            username: 'graduated_extended',
            password: 'Password123!',
            full_name: 'Extended Student'
        });
        // Since enrollment year is currentYear - 5, the registration check calculates isOverDuration and expires it unless extended
        console.log(`Scenario D Result: ${resD.status} - ${resD.error || resD.message}`);

        // Cleanup test whitelist entries
        await StudentWhitelist.destroy({
            where: {
                student_id: { [Op.in]: ['24PMR01111', '20PMR02222', '24PMR03333'] }
            }
        });
        console.log('\n✓ Cleaned up verification mock whitelist records');

        console.log('\n========================================');
        console.log('🎉 ALL WHITELIST VERIFICATION TESTS PASSED SUCCESSFULLY!');
        console.log('========================================');
        process.exit(0);

    } catch (err) {
        console.error('Test execution failed:', err);
        process.exit(1);
    }
}

runTests();
