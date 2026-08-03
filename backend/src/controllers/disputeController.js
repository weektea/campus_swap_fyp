import { Dispute, Transaction, User, Product, Category, SubCategory, UserInteraction } from '../models/index.js';
import { createNotification } from './notificationController.js';
import { emitToAdmins } from '../config/socket.js';
import { getCarbonValue } from './transactionController.js';
import { sendError } from '../middleware/authMiddleware.js';

const rollbackCarbonPoints = async (transaction) => {
    try {
        let co2Saved = 0.0;
        if (transaction.awarded_carbon_points !== null && transaction.awarded_carbon_points !== undefined) {
            co2Saved = parseFloat(transaction.awarded_carbon_points);
        } else {
            const product = await Product.findByPk(transaction.product_id, {
                include: [
                    { model: Category, as: 'categoryModel' },
                    { model: SubCategory, as: 'subcategoryModel' }
                ]
            });
            if (product) {
                const catName = product.categoryModel ? product.categoryModel.name : product.category;
                const subCatName = product.subcategoryModel ? product.subcategoryModel.name : null;
                co2Saved = getCarbonValue(catName, subCatName, product);
            } else {
                co2Saved = 2.5; // fallback
            }
        }

        if (transaction.buyer_id === transaction.seller_id) {
            await User.decrement(
                { items_reused: 1, total_carbon_saved: co2Saved, carbon_saved_buyer: co2Saved, carbon_saved_seller: co2Saved },
                { where: { id: transaction.buyer_id } }
            );
        } else {
            await User.decrement(
                { items_reused: 1, total_carbon_saved: co2Saved, carbon_saved_buyer: co2Saved },
                { where: { id: transaction.buyer_id } }
            );
            await User.decrement(
                { items_reused: 1, total_carbon_saved: co2Saved, carbon_saved_seller: co2Saved },
                { where: { id: transaction.seller_id } }
            );
        }
    } catch (e) {
        console.error('Failed to rollback carbon points:', e);
    }
};

export const createDispute = async (req, res) => {
    try {
        const complainant_id = req.user.id;
        const { transaction_id, category, reason, description, evidence_urls } = req.body;
        const selectedReason = reason || category;

        if (!transaction_id || !description) {
            return res.status(400).json({ error: 'Missing dispute details' });
        }

        const transaction = await Transaction.findByPk(transaction_id);
        if (!transaction) return res.status(404).json({ error: 'Transaction not found' });

        // Fix 4: Ensure complainant is either buyer or seller of the transaction
        if (String(complainant_id) !== String(transaction.buyer_id) && String(complainant_id) !== String(transaction.seller_id)) {
            return sendError(res, 403, 'Access Denied: You are not authorized to file a dispute against this transaction.');
        }

        // 7-day Post-Completion Window Check
        if (transaction.status === 'Completed') {
            const completedDate = transaction.completed_at || transaction.updatedAt;
            if (completedDate) {
                const diffMs = Date.now() - new Date(completedDate).getTime();
                const diffDays = diffMs / (1000 * 60 * 60 * 24);
                if (diffDays > 7) {
                    return res.status(400).json({ error: 'Dispute channel closed: Disputes must be opened within 7 days of order completion.' });
                }
            }
        }

        let dbReason = 'Other';
        if (selectedReason && typeof selectedReason === 'string') {
            const lowerReason = selectedReason.toLowerCase();
            if (lowerReason.includes('not received') || lowerReason.includes('received')) {
                dbReason = 'Not Received';
            } else if (lowerReason.includes('rental damage')) {
                dbReason = 'Rental Damage';
            } else if (lowerReason.includes('damaged')) {
                dbReason = 'Damaged';
            } else if (lowerReason.includes('fraud') || lowerReason.includes('fake')) {
                dbReason = 'Fraud';
            }
        }

        const dispute = await Dispute.create({
            transaction_id,
            complainant_id,
            reason: dbReason,
            description,
            evidence_urls: evidence_urls || [],
            status: 'New'
        });

        // Set transaction status to Disputed to lock the transaction
        transaction.pre_dispute_status = transaction.status;
        transaction.status = 'Disputed';
        await transaction.save();

        // Identify other party to notify
        const otherPartyId = complainant_id === transaction.buyer_id ? transaction.seller_id : transaction.buyer_id;

        // Notify other party
        await createNotification(
            otherPartyId,
            'Transaction Disputed',
            `A dispute was filed against this transaction. A moderator will review it soon.`,
            'Transaction',
            dispute.id
        );

        // Also notify the complainant that it was received
        await createNotification(
            complainant_id,
            'Dispute Submitted',
            `Your dispute has been logged. Our moderation team will investigate.`,
            'System',
            dispute.id
        );

        // Emit new dispute event to admin room
        emitToAdmins('new_dispute_raised', dispute);

        res.status(201).json(dispute);
    } catch (error) {
        console.error('Create Dispute Error:', error);
        res.status(500).json({ error: 'Failed to create dispute' });
    }
};

export const triageDispute = async (req, res) => {
    try {
        const { id } = req.params;
        const { action, mod_notes } = req.body; // 'Dismiss', 'Investigate', 'Escalate'

        const dispute = await Dispute.findByPk(id);
        if (!dispute) return res.status(404).json({ error: 'Dispute not found' });
        if (dispute.status === 'Resolved') {
            return res.status(400).json({ error: 'This dispute has already been resolved by an Admin and cannot be modified.' });
        }

        if (action === 'Dismiss') {
            dispute.status = 'Resolved';
            const transaction = await Transaction.findByPk(dispute.transaction_id);
            if (transaction) {
                const restoredStatus = transaction.pre_dispute_status || 'Completed';
                transaction.status = restoredStatus;
                transaction.pre_dispute_status = null;
                await transaction.save();

                // Synchronize Product status
                if (restoredStatus === 'Completed') {
                    await Product.update(
                        { status: 'Sold' },
                        { where: { id: transaction.product_id } }
                    );
                } else {
                    await Product.update(
                        { status: 'Reserved' },
                        { where: { id: transaction.product_id } }
                    );
                }
            }
        } else if (action === 'Investigate') {
            dispute.status = 'Investigating';
            const transaction = await Transaction.findByPk(dispute.transaction_id);
            if (transaction) {
                const defendantId = dispute.complainant_id === transaction.buyer_id ? transaction.seller_id : transaction.buyer_id;
                await createNotification(
                    defendantId,
                    'Dispute Under Investigation',
                    `A dispute against transaction #${transaction.id.toString().substring(0, 8).toUpperCase()} is under investigation. Please upload counter-evidence within 48 hours.`,
                    'Transaction',
                    dispute.id
                );
            }
        } else if (action === 'Escalate') {
            dispute.status = 'Escalated';
        } else {
            return res.status(400).json({ error: 'Invalid triage action' });
        }

        if (mod_notes) dispute.admin_notes = mod_notes; // Storing mod notes in admin_notes field
        dispute.handled_by = req.user.id;
        await dispute.save();

        res.json({ message: `Dispute triaged as ${action}`, dispute });
    } catch (error) {
        console.error('Triage Dispute Error:', error);
        res.status(500).json({ error: 'Failed to triage dispute' });
    }
};

export const arbitrateDispute = async (req, res) => {
    try {
        const { id } = req.params;
        const { winning_party, admin_notes, action_on_loser } = req.body; // 'Buyer' or 'Seller', action_on_loser: 'none' / 'warn' / 'ban'

        const dispute = await Dispute.findByPk(id);
        if (!dispute) return res.status(404).json({ error: 'Dispute not found' });
        if (dispute.status !== 'Escalated') {
            return res.status(400).json({ error: 'Only escalated disputes can be arbitrated' });
        }

        const transaction = await Transaction.findByPk(dispute.transaction_id);
        if (!transaction) return res.status(404).json({ error: 'Transaction not found' });

        if (winning_party === 'Buyer') {
            // Buyer wins: Cancel order, refund
            const wasCompleted = transaction.completed_at !== null;
            transaction.status = 'Cancelled';
            dispute.status = 'Resolved';
            await transaction.save();

            if (wasCompleted) {
                // Deduct previously awarded carbon points and items reused count
                await rollbackCarbonPoints(transaction);

                // Set product status to Suspended so it's not Available
                await Product.update(
                    { status: 'Suspended' },
                    { where: { id: transaction.product_id } }
                );
            } else {
                // If not completed yet, product can revert to Available
                await Product.update(
                    { status: 'Available' },
                    { where: { id: transaction.product_id } }
                );
            }
        } else if (winning_party === 'Seller') {
            // Seller wins: Complete order, deposit to seller
            const wasCompleted = transaction.completed_at !== null;
            transaction.status = 'Completed';
            if (!transaction.completed_at) {
                transaction.completed_at = new Date();
            }
            dispute.status = 'Resolved';
            await transaction.save();

            const product = await Product.findByPk(transaction.product_id, {
                include: [
                    { model: Category, as: 'categoryModel' },
                    { model: SubCategory, as: 'subcategoryModel' }
                ]
            });

            // Set product status to Sold or Available depending on if Rent
            if (product) {
                if (product.type === 'Rent') {
                    await Product.update(
                        { status: 'Available' },
                        { where: { id: transaction.product_id } }
                    );
                } else {
                    await Product.update(
                        { status: 'Sold' },
                        { where: { id: transaction.product_id } }
                    );
                }
            }

            // Damage Compensation rules:
            if (dispute.reason === 'Rental Damage' && product && product.type === 'Rent') {
                const depositVal = product.rental_deposit ? parseFloat(product.rental_deposit) : 0.0;
                console.log(`[Damage Compensation Resolved] Seller won dispute. Buyer's entire rental deposit of RM ${depositVal.toFixed(2)} forfeited to Seller.`);
                
                const buyer = await User.findByPk(transaction.buyer_id);
                if (buyer) {
                    buyer.reputation_score = Math.max(1.0, parseFloat(buyer.reputation_score || 5.0) - 1.0);
                    await buyer.save();
                }
            }

            // Award carbon points if it was NOT completed before
            if (!wasCompleted) {
                let co2Saved = 0.0;
                if (product) {
                     const catName = product.categoryModel ? product.categoryModel.name : product.category;
                     const subCatName = product.subcategoryModel ? product.subcategoryModel.name : null;
                     co2Saved = getCarbonValue(catName, subCatName, product);
                }

                // Calculate 2% Platform Fee (based on transaction.amount)
                const platformFee = parseFloat((parseFloat(transaction.amount) * 0.02).toFixed(2));
                transaction.platform_fee = platformFee;
                transaction.awarded_carbon_points = co2Saved;
                await transaction.save();

                if (product) {
                     if (transaction.buyer_id === transaction.seller_id) {
                          await User.increment(
                              { items_reused: 1, total_carbon_saved: co2Saved, carbon_saved_buyer: co2Saved, carbon_saved_seller: co2Saved, accumulated_balance_due: platformFee },
                              { where: { id: transaction.buyer_id } }
                          );
                      } else {
                          await User.increment(
                              { items_reused: 1, total_carbon_saved: co2Saved, carbon_saved_buyer: co2Saved },
                              { where: { id: transaction.buyer_id } }
                          );
                          await User.increment(
                              { items_reused: 1, total_carbon_saved: co2Saved, carbon_saved_seller: co2Saved, accumulated_balance_due: platformFee },
                              { where: { id: transaction.seller_id } }
                          );
                      }
                 }

                 // Log interaction: 'buy' for Buyer (Idempotency assured)
                 try {
                     await UserInteraction.findOrCreate({
                         where: {
                             user_id: transaction.buyer_id,
                             product_id: transaction.product_id,
                             interaction_type: 'buy'
                         },
                         defaults: {
                             weight: 10
                         }
                     });
                 } catch (interactionError) {
                     console.error('Failed to log buy interaction in dispute resolution:', interactionError);
                 }
            }
        } else {
            return res.status(400).json({ error: 'winning_party must be Buyer or Seller' });
        }

        dispute.admin_notes = admin_notes || 'Arbitrated by admin.';
        dispute.handled_by = req.user.id;
        await dispute.save();

        // Enforce warning/ban logic & reputation score penalty on loser
        const loserId = winning_party === 'Buyer' ? transaction.seller_id : transaction.buyer_id;
        const loser = await User.findByPk(loserId);
        if (loser) {
            const currentScore = parseFloat(loser.reputation_score !== undefined && loser.reputation_score !== null ? loser.reputation_score : 5.0);
            loser.reputation_score = Math.max(1.0, parseFloat((currentScore - 1.0).toFixed(1)));

            if (action_on_loser === 'ban') {
                loser.is_active = false;
                loser.deactivation_reason = `Suspended due to losing dispute #${dispute.id} in transaction #${transaction.id}`;
                await loser.save();

                await createNotification(
                    loserId,
                    'Account Suspended',
                    `Your account has been suspended following the arbitration of dispute #${dispute.id.toString().substring(0, 8).toUpperCase()}.`,
                    'System',
                    transaction.id
                );
            } else if (action_on_loser === 'warn') {
                loser.warning_count = (loser.warning_count || 0) + 1;
                await loser.save();

                await createNotification(
                    loserId,
                    'Account Warning Issued',
                    `A formal warning has been issued to your account following dispute arbitration. Your reputation score dropped to ${loser.reputation_score.toFixed(1)}.`,
                    'System',
                    transaction.id
                );
            } else {
                await loser.save();
                await createNotification(
                    loserId,
                    'Dispute Resolution & Score Penalty',
                    `The dispute #${dispute.id.toString().substring(0, 8).toUpperCase()} has been arbitrated against you. A 1.0 penalty was applied to your reputation score.`,
                    'System',
                    dispute.id
                );
            }
        }

        // Notify the winner
        const winnerId = winning_party === 'Buyer' ? transaction.buyer_id : transaction.seller_id;
        await createNotification(
            winnerId,
            'Dispute Won',
            `The dispute #${dispute.id.toString().substring(0, 8).toUpperCase()} has been resolved in your favor.`,
            'System',
            dispute.id
        );

        res.json({ message: `Dispute resolved in favor of ${winning_party}`, dispute, transaction });
    } catch (error) {
        console.error('Arbitrate Dispute Error:', error);
        res.status(500).json({ error: 'Failed to arbitrate dispute' });
    }
};
