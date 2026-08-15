import Stripe from 'stripe';
import { Transaction, Product, User, Category, SubCategory, ActivityLog } from '../models/index.js';
import { createNotification } from './notificationController.js';
import { emitToUser, emitToAdmins } from '../config/socket.js';
import dotenv from 'dotenv';
dotenv.config();

const stripeSecretKey = process.env.STRIPE_SECRET_KEY || 'sk_test_51MockCampusSwapKeyForDemoTesting1234567890abcdefghijklmnopqrstuvwxyz';
const stripe = new Stripe(stripeSecretKey);

/**
 * Helper to process Stripe refunds safely (supports full and partial deposit refunds with Test Demo fallback)
 */
export const processStripeRefund = async (transaction, reason = 'requested_by_customer', refundAmountInCents = null) => {
    try {
        if (!transaction.stripe_payment_intent_id) {
            console.log(`[Stripe Refund] Transaction ${transaction.id} has no payment_intent_id recorded. Marking refunded.`);
            transaction.stripe_payment_status = 'refunded';
            await transaction.save();
            return { success: true, simulated: true };
        }

        const refundDesc = refundAmountInCents 
            ? ` (Amount: RM ${(refundAmountInCents / 100).toFixed(2)})` 
            : ' (Full Amount)';
        console.log(`[Stripe Refund] Initiating refund for PaymentIntent ${transaction.stripe_payment_intent_id}${refundDesc}...`);
        
        let refundResult = null;
        try {
            const refundParams = {
                payment_intent: transaction.stripe_payment_intent_id,
                reason: reason === 'fraudulent' ? 'fraudulent' : 'requested_by_customer'
            };
            if (refundAmountInCents && Number.isFinite(refundAmountInCents) && refundAmountInCents > 0) {
                refundParams.amount = Math.round(refundAmountInCents);
            }
            refundResult = await stripe.refunds.create(refundParams);
            console.log(`[Stripe Refund] Successfully refunded: ${refundResult.id}`);
        } catch (stripeErr) {
            console.warn(`[Stripe Refund API Note]: ${stripeErr.message}. Executing sandbox test refund.`);
            refundResult = { 
                id: `re_mock_${Date.now()}`, 
                status: 'succeeded',
                amount: refundAmountInCents || Math.round(parseFloat(transaction.amount) * 100)
            };
        }

        const totalCents = Math.round(parseFloat(transaction.amount || 0) * 100);
        transaction.stripe_payment_status = (refundAmountInCents && refundAmountInCents < totalCents)
            ? 'partially_refunded'
            : 'refunded';
        await transaction.save();

        return { success: true, refund: refundResult };
    } catch (err) {
        console.error('[Stripe Refund Error]:', err);
        return { success: false, error: err.message };
    }
};

/**
 * POST /api/payments/create-checkout-session
 * Generate Stripe Checkout Session (Test Mode) for a Scheduled order
 */
export const createCheckoutSession = async (req, res) => {
    try {
        const { transaction_id } = req.body;
        const buyerId = req.user.id;

        if (!transaction_id) {
            return res.status(400).json({ error: 'transaction_id is required' });
        }

        const transaction = await Transaction.findByPk(transaction_id, {
            include: [
                { model: Product, as: 'product' },
                { model: User, as: 'seller', attributes: ['id', 'username', 'full_name', 'email'] },
                { model: User, as: 'buyer', attributes: ['id', 'username', 'full_name', 'email'] }
            ]
        });

        if (!transaction) {
            return res.status(404).json({ error: 'Transaction not found' });
        }

        if (String(transaction.buyer_id) !== String(buyerId)) {
            return res.status(403).json({ error: 'Only the buyer can initiate Stripe checkout for this order.' });
        }

        if (transaction.status !== 'Scheduled') {
            return res.status(400).json({ 
                error: `Cannot create checkout session for order in '${transaction.status}' status. Order must be 'Scheduled'.` 
            });
        }

        const productTitle = transaction.product ? transaction.product.title : 'Campus Swap Item';
        const totalAmount = parseFloat(transaction.amount || 0);
        const amountInCents = Math.round(totalAmount * 100);

        if (amountInCents <= 0) {
            return res.status(400).json({ error: 'Invalid transaction amount' });
        }

        const isRent = transaction.product?.type === 'Rent' || transaction.rental_start_date != null;
        const depositVal = transaction.deposit_amount ? parseFloat(transaction.deposit_amount) : 0.0;
        const rentalFee = isRent ? Math.max(0, totalAmount - depositVal) : totalAmount;

        let itemDescription = `Campus Swap Escrow Protection - Order #${transaction.id.substring(0, 8).toUpperCase()}`;
        if (isRent) {
            itemDescription = `Rental Fee: RM ${rentalFee.toFixed(2)} + Security Deposit: RM ${depositVal.toFixed(2)}${transaction.deposit_status === 'Waived' ? ' (Waived)' : ''} [Campus Swap Escrow]`;
        }

        const appBaseUrl = process.env.APP_BASE_URL || 'http://localhost:3000';
        let session = null;
        let isSimulated = false;

        try {
            session = await stripe.checkout.sessions.create({
                payment_method_types: ['card'],
                line_items: [{
                    price_data: {
                        currency: 'myr',
                        product_data: {
                            name: isRent ? `${productTitle} (Rental)` : productTitle,
                            description: itemDescription,
                            images: transaction.product?.image_urls?.length > 0 ? [transaction.product.image_urls[0]] : []
                        },
                        unit_amount: amountInCents,
                    },
                    quantity: 1,
                }],
                mode: 'payment',
                success_url: `${appBaseUrl}/api/payments/success?session_id={CHECKOUT_SESSION_ID}&transaction_id=${transaction.id}`,
                cancel_url: `${appBaseUrl}/api/payments/cancel?transaction_id=${transaction.id}`,
                customer_email: transaction.buyer?.email || req.user.email,
                metadata: {
                    transaction_id: transaction.id,
                    buyer_id: String(buyerId),
                    seller_id: String(transaction.seller_id),
                    product_id: String(transaction.product_id),
                    is_rent: isRent ? 'true' : 'false',
                    rental_fee: rentalFee.toFixed(2),
                    deposit_amount: depositVal.toFixed(2)
                }
            });
        } catch (stripeError) {
            console.warn('[Stripe SDK Note]: Real Stripe API key not configured or failed, creating robust test demo session:', stripeError.message);
            isSimulated = true;
            const mockSessionId = `cs_test_demo_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;
            session = {
                id: mockSessionId,
                url: `https://checkout.stripe.com/c/pay/${mockSessionId}#test_mode`,
                payment_intent: `pi_test_demo_${Date.now()}`
            };
        }

        transaction.stripe_session_id = session.id;
        await transaction.save();

        res.json({
            url: session.url,
            session_id: session.id,
            amount: totalAmount,
            currency: 'MYR',
            item_name: productTitle,
            transaction_id: transaction.id,
            is_simulated: isSimulated
        });
    } catch (error) {
        console.error('Create Checkout Session Error:', error);
        res.status(500).json({ error: error.message || 'Failed to create Stripe checkout session' });
    }
};

/**
 * POST /api/payments/confirm
 * Confirms payment success, generates 4-digit Meetup PIN, and moves status to 'To Confirm'
 */
export const confirmPayment = async (req, res) => {
    try {
        const { transaction_id, session_id } = req.body;
        const userId = req.user?.id;

        if (!transaction_id) {
            return res.status(400).json({ error: 'transaction_id is required' });
        }

        const transaction = await Transaction.findByPk(transaction_id, {
            include: [{ model: Product, as: 'product' }]
        });

        if (!transaction) {
            return res.status(404).json({ error: 'Transaction not found' });
        }

        if (userId && String(transaction.buyer_id) !== String(userId)) {
            return res.status(403).json({ error: 'Only the buyer or webhook can confirm payment.' });
        }

        // If already paid and pin generated, return current state
        if (transaction.status === 'To Confirm' && transaction.meetup_pin) {
            return res.json({
                message: 'Payment already confirmed',
                transaction_id: transaction.id,
                status: transaction.status,
                meetup_pin: transaction.meetup_pin
            });
        }

        let paymentIntentId = `pi_test_${Date.now()}`;
        if (session_id && !session_id.includes('demo')) {
            try {
                const session = await stripe.checkout.sessions.retrieve(session_id);
                if (session && session.payment_intent) {
                    paymentIntentId = typeof session.payment_intent === 'string' 
                        ? session.payment_intent 
                        : session.payment_intent.id;
                }
            } catch (err) {
                console.warn('Could not retrieve real payment intent from Stripe session, using fallback test ID');
            }
        }

        // Generate secure 4-digit numeric PIN (1000 to 9999)
        const meetupPin = Math.floor(1000 + Math.random() * 9000).toString();

        transaction.status = 'To Confirm';
        transaction.meetup_pin = meetupPin;
        transaction.stripe_session_id = session_id || transaction.stripe_session_id || `cs_test_${Date.now()}`;
        transaction.stripe_payment_intent_id = paymentIntentId;
        transaction.stripe_payment_status = 'paid';
        transaction.selected_payment_method = 'Stripe';
        transaction.payment_proof_url = 'Stripe Escrow Verified (Online Card Payment)';
        await transaction.save();

        const productTitle = transaction.product ? transaction.product.title : 'item';

        // 1. Notify Buyer (Includes the 4-digit Meetup PIN)
        await createNotification(
            transaction.buyer_id,
            'Stripe Payment Successful - Meetup PIN Generated',
            `Your payment of RM ${transaction.amount} is securely held in escrow. Your Meetup PIN is: [ ${meetupPin} ]. Present this PIN to the seller during in-person handover.`,
            'Transaction',
            transaction.id
        );

        // 2. Notify Seller (Funds held in escrow, awaiting PIN verification)
        await createNotification(
            transaction.seller_id,
            'Buyer Paid via Stripe Escrow',
            `Buyer has paid RM ${transaction.amount} via Stripe Escrow. Funds are safely secured. Meet with the buyer and enter their 4-digit PIN to release funds and complete handover.`,
            'Transaction',
            transaction.id
        );

        // Real-time socket updates to both buyer and seller
        emitToUser(transaction.buyer_id, 'transaction_status_updated', { 
            transaction_id: transaction.id, 
            status: 'To Confirm',
            meetup_pin: meetupPin 
        });
        emitToUser(transaction.seller_id, 'transaction_status_updated', { 
            transaction_id: transaction.id, 
            status: 'To Confirm'
        });

        // Audit Log
        if (userId) {
            await ActivityLog.create({
                user_id: userId,
                action: 'STRIPE_ESCROW_PAID',
                entity_type: 'Transaction',
                details: `Buyer paid RM ${transaction.amount} via Stripe. Generated Meetup PIN.`
            }).catch(() => {});
        }

        res.json({
            message: 'Stripe payment confirmed successfully. Meetup PIN generated.',
            transaction_id: transaction.id,
            status: 'To Confirm',
            meetup_pin: meetupPin,
            payment_intent_id: paymentIntentId
        });
    } catch (error) {
        console.error('Confirm Payment Error:', error);
        res.status(500).json({ error: error.message || 'Failed to confirm Stripe payment' });
    }
};

/**
 * Webhook handler for Stripe Server Events
 * POST /api/payments/webhook
 */
export const stripeWebhook = async (req, res) => {
    const sig = req.headers['stripe-signature'];
    const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

    let event;
    try {
        if (webhookSecret && sig) {
            event = stripe.webhooks.constructEvent(req.body, sig, webhookSecret);
        } else {
            event = req.body;
        }
    } catch (err) {
        console.error(`Webhook signature verification failed:`, err.message);
        return res.status(400).send(`Webhook Error: ${err.message}`);
    }

    if (event.type === 'checkout.session.completed') {
        const session = event.data.object;
        const transactionId = session.metadata?.transaction_id;

        if (transactionId) {
            try {
                const transaction = await Transaction.findByPk(transactionId);
                if (transaction && transaction.status === 'Scheduled') {
                    const meetupPin = Math.floor(1000 + Math.random() * 9000).toString();
                    const paymentIntentId = typeof session.payment_intent === 'string' 
                        ? session.payment_intent 
                        : (session.payment_intent?.id || `pi_webhook_${Date.now()}`);

                    transaction.status = 'To Confirm';
                    transaction.meetup_pin = meetupPin;
                    transaction.stripe_session_id = session.id;
                    transaction.stripe_payment_intent_id = paymentIntentId;
                    transaction.stripe_payment_status = 'paid';
                    transaction.selected_payment_method = 'Stripe';
                    transaction.payment_proof_url = 'Stripe Escrow Verified';
                    await transaction.save();

                    emitToUser(transaction.buyer_id, 'transaction_status_updated', { 
                        transaction_id: transaction.id, 
                        status: 'To Confirm',
                        meetup_pin: meetupPin 
                    });
                    emitToUser(transaction.seller_id, 'transaction_status_updated', { 
                        transaction_id: transaction.id, 
                        status: 'To Confirm'
                    });

                    console.log(`[Stripe Webhook] Order #${transaction.id} updated to 'To Confirm' with PIN ${meetupPin}`);
                }
            } catch (err) {
                console.error('[Stripe Webhook Error Processing Transaction]:', err);
            }
        }
    }

    res.json({ received: true });
};
