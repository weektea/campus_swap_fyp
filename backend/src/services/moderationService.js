import { ModerationRule, FlaggedContent, ActivityLog, User } from '../models/index.js';
import { Op } from 'sequelize';

class ModerationService {
    constructor() {
        this.cachedRules = null;
        this.lastCacheTime = 0;
        this.CACHE_TTL_MS = 60 * 1000; // 1 minute in-memory cache
    }

    // Default Seed Rules
    getDefaultRules() {
        return [
            {
                name: 'Default Profanity & Abusive Language',
                category: 'profanity',
                match_type: 'keyword',
                pattern: 'fuck, shit, bitch, asshole, cunt, dick, bastard',
                severity: 'medium',
                action: 'mask',
                is_enabled: true,
                description: 'Masks offensive profanity with *** while allowing message delivery.'
            },
            {
                name: 'Severe Harassment & Physical Threat',
                category: 'harassment',
                match_type: 'regex',
                pattern: '\\b(?:kill\\s+you|beat\\s+you\\s+up|die\\s+bitch|threaten\\s+to\\s+hurt)\\b',
                severity: 'critical',
                action: 'block',
                is_enabled: true,
                description: 'Blocks severe threats or violent harassment immediately.'
            },
            {
                name: 'Malaysian Phone Number Detector',
                category: 'privacy',
                match_type: 'pattern',
                pattern: '(?:\\+?60|0)[1-9]\\d{7,9}|01\\d[- ]?\\d{7,8}',
                severity: 'high',
                action: 'flag',
                is_enabled: true,
                description: 'Detects phone numbers to prevent privacy leaks and off-platform redirection.'
            },
            {
                name: 'Email Address Exposure Detector',
                category: 'privacy',
                match_type: 'pattern',
                pattern: '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}',
                severity: 'medium',
                action: 'flag',
                is_enabled: true,
                description: 'Flags unencrypted email addresses shared in user content.'
            },
            {
                name: 'Malaysian NRIC / IC Detector',
                category: 'privacy',
                match_type: 'pattern',
                pattern: '\\b\\d{6}[- ]?\\d{2}[- ]?\\d{4}\\b',
                severity: 'critical',
                action: 'block',
                is_enabled: true,
                description: 'Blocks transmission of sensitive Malaysian Identity Card (NRIC) numbers.'
            },
            {
                name: 'Student ID Detector',
                category: 'privacy',
                match_type: 'pattern',
                pattern: '\\b\\d{2}[A-Z]{3}\\d{5}\\b',
                severity: 'low',
                action: 'flag',
                is_enabled: true,
                description: 'Flags institutional student registration IDs shared publicly.'
            },
            {
                name: 'Contextual WhatsApp Solicitation',
                category: 'off_platform_contact',
                match_type: 'regex',
                pattern: '(?:whatsapp|wa|contact|dm|pm|call|msg|text)\\s*(?:me|us)?\\s*(?:at|on|via)?\\s*[:\\-\\s]?\\s*(?:\\+?\\d{7,15}|@[a-z0-9_]+|wa\\.me\\/\\S+)|wa\\.me\\/\\S+|\\b(?:whatsapp|wa)\\s+(?:me|us)\\b',
                severity: 'high',
                action: 'flag',
                is_enabled: true,
                description: 'Detects attempts to lure students to external WhatsApp channels.'
            },
            {
                name: 'Contextual Telegram Solicitation',
                category: 'off_platform_contact',
                match_type: 'regex',
                pattern: '(?:telegram|tg)\\s*(?:me|us)?\\s*(?:at|on|via)?\\s*[:\\-\\s]?\\s*(?:@[a-z0-9_]+|t\\.me\\/\\S+)|t\\.me\\/\\S+|\\b(?:telegram|tg)\\s+(?:me|us)\\b',
                severity: 'high',
                action: 'flag',
                is_enabled: true,
                description: 'Detects external Telegram invitation links and contact directives.'
            },
            {
                name: 'Religious Hate / Abuse Safeguard',
                category: 'religious_sensitive',
                match_type: 'regex',
                pattern: '\\b(?:fuck|kill|hate|burn|destroy|curse)\\s+(?:islam|muslim|christian|church|mosque|buddhist|temple|hindu|religion)\\b',
                severity: 'high',
                action: 'flag',
                is_enabled: true,
                description: 'Flags derogatory combinations attacking religious communities while preserving non-hostile academic/cultural discourse.'
            }
        ];
    }

    // Seed default rules if table is empty
    async seedDefaultRulesIfEmpty() {
        try {
            const count = await ModerationRule.count();
            if (count === 0) {
                const defaults = this.getDefaultRules();
                await ModerationRule.bulkCreate(defaults);
                console.log(`[ModerationService] Seeded ${defaults.length} default moderation rules.`);
                this.invalidateCache();
            }
        } catch (err) {
            console.error('[ModerationService] Failed to seed default rules:', err);
        }
    }

    // Invalidate Cache
    invalidateCache() {
        this.cachedRules = null;
        this.lastCacheTime = 0;
    }

    // Fetch enabled rules with caching
    async getActiveRules() {
        const now = Date.now();
        if (this.cachedRules && (now - this.lastCacheTime < this.CACHE_TTL_MS)) {
            return this.cachedRules;
        }

        try {
            let rules = await ModerationRule.findAll({
                where: { is_enabled: true },
                order: [['severity', 'DESC'], ['createdAt', 'ASC']]
            });

            if (rules.length === 0) {
                await this.seedDefaultRulesIfEmpty();
                rules = await ModerationRule.findAll({
                    where: { is_enabled: true },
                    order: [['severity', 'DESC'], ['createdAt', 'ASC']]
                });
            }

            this.cachedRules = rules;
            this.lastCacheTime = now;
            return this.cachedRules;
        } catch (err) {
            console.error('[ModerationService] Failed to load rules from DB, falling back to static defaults:', err);
            return this.getDefaultRules();
        }
    }

    // Helper: Mask sensitive text snippet for privacy preservation (e.g. "...whatsapp me at 012-***...")
    createPrivacyPreservedSnippet(fullText, matchStr, category) {
        if (!fullText) return '';
        const matchIndex = fullText.toLowerCase().indexOf(matchStr.toLowerCase());
        const start = Math.max(0, matchIndex - 15);
        const end = Math.min(fullText.length, matchIndex + matchStr.length + 15);
        let snippet = (start > 0 ? '...' : '') + fullText.substring(start, end) + (end < fullText.length ? '...' : '');

        // Mask out numbers and emails in the snippet to strictly guard student privacy
        if (category === 'privacy' || category === 'off_platform_contact') {
            snippet = snippet.replace(/\d{4,}/g, '***');
            snippet = snippet.replace(/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+/g, '***@***');
        }
        return snippet.substring(0, 250);
    }

    // Core Evaluation Engine
    async evaluateContent(text, context = {}) {
        if (!text || typeof text !== 'string') {
            return {
                isFlagged: false,
                isBlocked: false,
                action: 'allow',
                severity: 'low',
                sanitizedText: text || '',
                matchedRules: [],
                matchedCategories: [],
                feedbackMessage: null
            };
        }

        const rules = await this.getActiveRules();
        let sanitizedText = text;
        const matchedRules = [];
        const matchedCategories = new Set();
        let highestSeverity = 'low';
        let finalAction = 'allow'; // priority: block > mask > flag > warn > allow
        let feedbackMessage = null;

        const severityRank = { low: 1, medium: 2, high: 3, critical: 4 };
        const actionRank = { allow: 0, warn: 1, flag: 2, mask: 3, block: 4 };

        for (const rule of rules) {
            if (!rule.is_enabled) continue;

            let isMatch = false;
            let matchedSubstring = '';

            try {
                if (rule.match_type === 'keyword') {
                    // Split comma-separated keywords and match as whole words
                    const keywords = rule.pattern.split(',').map(k => k.trim()).filter(Boolean);
                    for (const kw of keywords) {
                        const escaped = kw.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');
                        const regex = new RegExp(`\\b${escaped}\\b`, 'gi');
                        if (regex.test(sanitizedText)) {
                            isMatch = true;
                            matchedSubstring = kw;
                            if (rule.action === 'mask') {
                                sanitizedText = sanitizedText.replace(regex, '***');
                            }
                        }
                    }
                } else if (rule.match_type === 'phrase') {
                    const escaped = rule.pattern.trim().replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');
                    const regex = new RegExp(escaped, 'gi');
                    if (regex.test(sanitizedText)) {
                        isMatch = true;
                        matchedSubstring = rule.pattern;
                        if (rule.action === 'mask') {
                            sanitizedText = sanitizedText.replace(regex, '***');
                        }
                    }
                } else if (rule.match_type === 'regex' || rule.match_type === 'pattern') {
                    const regex = new RegExp(rule.pattern.trim(), 'gi');
                    const matchResult = sanitizedText.match(regex);
                    if (matchResult && matchResult.length > 0) {
                        isMatch = true;
                        matchedSubstring = matchResult[0];
                        if (rule.action === 'mask') {
                            sanitizedText = sanitizedText.replace(regex, '***');
                        }
                    }
                }
            } catch (evalErr) {
                console.error(`[ModerationService] Error evaluating rule [${rule.name}]:`, evalErr);
            }

            if (isMatch) {
                matchedRules.push({
                    id: rule.id,
                    name: rule.name,
                    category: rule.category,
                    severity: rule.severity,
                    action: rule.action,
                    matchedSubstring
                });
                matchedCategories.add(rule.category);

                // Update severity ranking
                if (severityRank[rule.severity] > severityRank[highestSeverity]) {
                    highestSeverity = rule.severity;
                }

                // Update action ranking
                if (actionRank[rule.action] > actionRank[finalAction]) {
                    finalAction = rule.action;
                }
            }
        }

        const isFlagged = matchedRules.length > 0 && finalAction !== 'allow';
        const isBlocked = finalAction === 'block';

        // Prepare human-friendly, empathetic feedback message for client
        if (isBlocked) {
            if (matchedCategories.has('privacy')) {
                feedbackMessage = 'Message blocked: For your security, sharing sensitive identity credentials (such as IC or bank cards) is prohibited.';
            } else if (matchedCategories.has('harassment')) {
                feedbackMessage = 'Message blocked: Content contains abusive language or threats violating community guidelines.';
            } else {
                feedbackMessage = 'Message blocked: Content violates Campus Swap safety standards.';
            }
        } else if (finalAction === 'warn' || finalAction === 'flag') {
            if (matchedCategories.has('off_platform_contact')) {
                feedbackMessage = 'Notice: Keep communications within Campus Swap to stay protected under campus safety escrow.';
            } else if (matchedCategories.has('privacy')) {
                feedbackMessage = 'Notice: Sharing personal contact information may expose your privacy.';
            }
        }

        // Asynchronously record to FlaggedContent review queue (if flagged or blocked)
        if (isFlagged && context.userId) {
            const firstHit = matchedRules[0];
            const safeSnippet = this.createPrivacyPreservedSnippet(text, firstHit.matchedSubstring || '', firstHit.category);

            FlaggedContent.create({
                source_type: context.sourceType || 'message',
                source_id: context.sourceId ? String(context.sourceId) : null,
                user_id: context.userId,
                category: Array.from(matchedCategories).join(', '),
                severity: highestSeverity,
                action_taken: finalAction,
                matched_rule_id: firstHit.id || null,
                matched_rule_name: firstHit.name,
                matched_snippet: safeSnippet,
                review_status: 'pending'
            }).catch(logErr => {
                console.error('[ModerationService] Failed to create FlaggedContent log:', logErr);
            });
        }

        return {
            isFlagged,
            isBlocked,
            action: finalAction,
            severity: highestSeverity,
            sanitizedText,
            matchedRules,
            matchedCategories: Array.from(matchedCategories),
            feedbackMessage
        };
    }
}

const moderationService = new ModerationService();
export default moderationService;
