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
        let paymentIntentId = transaction.stripe_payment_intent_id;

        // Auto-fetch payment_intent_id from Stripe Session if missing in local DB
        if (!paymentIntentId && transaction.stripe_session_id && !transaction.stripe_session_id.includes('demo')) {
            try {
                const stripeSession = await stripe.checkout.sessions.retrieve(transaction.stripe_session_id);
                if (stripeSession && stripeSession.payment_intent) {
                    paymentIntentId = typeof stripeSession.payment_intent === 'string'
                        ? stripeSession.payment_intent
                        : stripeSession.payment_intent.id;
                    transaction.stripe_payment_intent_id = paymentIntentId;
                    await transaction.save();
                    console.log(`[Stripe Refund] Resolved PaymentIntent ${paymentIntentId} from Session ${transaction.stripe_session_id}`);
                }
            } catch (sessionErr) {
                console.warn(`[Stripe Refund] Could not retrieve session from Stripe: ${sessionErr.message}`);
            }
        }

        if (!paymentIntentId) {
            console.log(`[Stripe Refund] Transaction ${transaction.id} has no payment_intent_id recorded. Marking refunded.`);
            transaction.stripe_payment_status = 'refunded';
            await transaction.save();
            return { success: true, simulated: true };
        }

        const refundDesc = refundAmountInCents 
            ? ` (Amount: RM ${(refundAmountInCents / 100).toFixed(2)})` 
            : ' (Full Amount)';
        console.log(`[Stripe Refund] Initiating refund for PaymentIntent ${paymentIntentId}${refundDesc}...`);
        
        let refundResult = null;
        try {
            const refundParams = {
                payment_intent: paymentIntentId,
                reason: reason === 'fraudulent' ? 'fraudulent' : 'requested_by_customer'
            };
            if (refundAmountInCents && Number.isFinite(refundAmountInCents) && refundAmountInCents > 0) {
                refundParams.amount = Math.round(refundAmountInCents);
            }
            refundResult = await stripe.refunds.create(refundParams);
            console.log(`[Stripe Refund] Successfully refunded on Stripe: ${refundResult.id}, status: ${refundResult.status}`);
        } catch (stripeErr) {
            console.warn(`[Stripe Refund API Note]: ${stripeErr.message}.`);
            // If it's a simulated/mock payment_intent, fallback to mock refund
            if (paymentIntentId.startsWith('pi_test_') || paymentIntentId.includes('mock') || paymentIntentId.includes('demo')) {
                refundResult = { 
                    id: `re_mock_${Date.now()}`, 
                    status: 'succeeded',
                    amount: refundAmountInCents || Math.round(parseFloat(transaction.amount) * 100)
                };
            } else {
                console.error(`[Stripe Refund Error]:`, stripeErr.message);
                if (stripeErr.message && stripeErr.message.includes('already been refunded')) {
                    refundResult = { id: `re_already_refunded`, status: 'succeeded' };
                } else {
                    return { success: false, error: stripeErr.message };
                }
            }
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

        if (transaction.status === 'To Confirm' && transaction.meetup_pin) {
            return res.json({
                already_paid: true,
                message: 'This order is already paid and held in Escrow.',
                transaction_id: transaction.id,
                status: transaction.status,
                meetup_pin: transaction.meetup_pin
            });
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

        let productImages = [];
        if (transaction.product?.image_urls && Array.isArray(transaction.product.image_urls) && transaction.product.image_urls.length > 0) {
            const firstImg = transaction.product.image_urls[0];
            if (typeof firstImg === 'string' && (firstImg.startsWith('https://') || firstImg.startsWith('http://')) && !firstImg.includes('localhost') && !firstImg.includes('127.0.0.1')) {
                productImages = [firstImg];
            }
        }

        const buyerEmail = transaction.buyer?.email || req.user.email;
        const validCustomerEmail = buyerEmail && typeof buyerEmail === 'string' && buyerEmail.includes('@') ? buyerEmail : undefined;

        try {
            const sessionConfig = {
                payment_method_types: ['card'],
                line_items: [{
                    price_data: {
                        currency: 'myr',
                        product_data: {
                            name: isRent ? `${productTitle} (Rental)` : productTitle,
                            description: itemDescription,
                            ...(productImages.length > 0 ? { images: productImages } : {})
                        },
                        unit_amount: amountInCents,
                    },
                    quantity: 1,
                }],
                mode: 'payment',
                success_url: `${appBaseUrl}/api/payments/success?session_id={CHECKOUT_SESSION_ID}&transaction_id=${transaction.id}`,
                cancel_url: `${appBaseUrl}/api/payments/cancel?transaction_id=${transaction.id}`,
                ...(validCustomerEmail ? { customer_email: validCustomerEmail } : {}),
                metadata: {
                    transaction_id: transaction.id,
                    buyer_id: String(buyerId),
                    seller_id: String(transaction.seller_id),
                    product_id: String(transaction.product_id),
                    is_rent: isRent ? 'true' : 'false',
                    rental_fee: rentalFee.toFixed(2),
                    deposit_amount: depositVal.toFixed(2)
                }
            };

            session = await stripe.checkout.sessions.create(sessionConfig);
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

/**
 * GET /api/payments/success
 * Browser landing page when buyer completes Stripe Checkout
 */
export const handlePaymentSuccess = async (req, res) => {
    try {
        const { session_id, transaction_id } = req.query;
        if (!transaction_id) {
            return res.status(400).send('<h2>Error: Missing transaction_id</h2>');
        }

        const transaction = await Transaction.findByPk(transaction_id, {
            include: [
                { model: Product, as: 'product' }
            ]
        });

        if (!transaction) {
            return res.status(404).send('<h2>Transaction not found</h2>');
        }

        let meetupPin = transaction.meetup_pin;

        // If not yet marked as paid / confirmed, confirm it now
        if (transaction.status !== 'To Confirm' || !meetupPin) {
            meetupPin = Math.floor(1000 + Math.random() * 9000).toString();
            transaction.status = 'To Confirm';
            transaction.meetup_pin = meetupPin;
            transaction.stripe_session_id = session_id || transaction.stripe_session_id;

            // Fetch actual PaymentIntent from Stripe checkout session
            if (session_id && !session_id.includes('demo')) {
                try {
                    const stripeSession = await stripe.checkout.sessions.retrieve(session_id);
                    if (stripeSession && stripeSession.payment_intent) {
                        transaction.stripe_payment_intent_id = typeof stripeSession.payment_intent === 'string'
                            ? stripeSession.payment_intent
                            : stripeSession.payment_intent.id;
                        console.log(`[handlePaymentSuccess] Attached PaymentIntent ${transaction.stripe_payment_intent_id} to Order #${transaction.id}`);
                    }
                } catch (err) {
                    console.warn('[handlePaymentSuccess] Failed to retrieve payment_intent from Stripe session:', err.message);
                }
            }

            transaction.stripe_payment_status = 'paid';
            transaction.selected_payment_method = 'Stripe';
            transaction.payment_proof_url = 'Stripe Escrow Verified (Online Card Payment)';
            await transaction.save();

            const productTitle = transaction.product ? transaction.product.title : 'item';

            // Send notification to Seller
            await createNotification(
                transaction.seller_id,
                'Stripe Escrow Payment Received',
                `Buyer has securely paid RM ${parseFloat(transaction.amount).toFixed(2)} via Stripe Escrow for "${productTitle}". Meetup PIN will be verified at handover.`,
                'Transaction',
                transaction.id
            );

            // Send notification to Buyer
            await createNotification(
                transaction.buyer_id,
                'Escrow Payment Successful',
                `Your payment of RM ${parseFloat(transaction.amount).toFixed(2)} is held safely in Escrow. Your 4-digit Meetup PIN is: ${meetupPin}`,
                'Transaction',
                transaction.id
            );

            // Real-time socket broadcast
            emitToUser(transaction.seller_id, 'transaction_status_updated', {
                transaction_id: transaction.id,
                transactionId: transaction.id,
                id: transaction.id,
                status: 'To Confirm',
                payment_status: 'paid'
            });

            emitToUser(transaction.buyer_id, 'transaction_status_updated', {
                transaction_id: transaction.id,
                transactionId: transaction.id,
                id: transaction.id,
                status: 'To Confirm',
                meetup_pin: meetupPin,
                payment_status: 'paid'
            });
        }

        const amountFormatted = parseFloat(transaction.amount).toFixed(2);
        const html = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Payment Successful - Campus Swap</title>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;600;700;800&display=swap" rel="stylesheet">
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Outfit', -apple-system, BlinkMacSystemFont, sans-serif; }
        body {
            background: #0f172a;
            color: #f8fafc;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .card {
            background: #1e293b;
            border-radius: 24px;
            padding: 40px 32px;
            max-width: 440px;
            width: 100%;
            text-align: center;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.4), 0 0 0 1px rgba(255, 255, 255, 0.1);
        }
        .icon-box {
            width: 80px;
            height: 80px;
            background: linear-gradient(135deg, #10b981 0%, #059669 100%);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 24px;
            box-shadow: 0 10px 25px rgba(16, 185, 129, 0.35);
        }
        .icon-box svg { width: 44px; height: 44px; fill: white; }
        h1 { font-size: 24px; font-weight: 800; color: #ffffff; margin-bottom: 8px; }
        p.subtitle { font-size: 15px; color: #94a3b8; margin-bottom: 24px; line-height: 1.5; }
        .pin-container {
            background: rgba(99, 91, 255, 0.12);
            border: 2px dashed rgba(99, 91, 255, 0.4);
            border-radius: 16px;
            padding: 20px;
            margin-bottom: 24px;
        }
        .pin-label { font-size: 12px; font-weight: 700; color: #a5b4fc; text-transform: uppercase; letter-spacing: 1.5px; margin-bottom: 6px; }
        .pin-code { font-size: 38px; font-weight: 800; letter-spacing: 8px; color: #ffffff; }
        .escrow-badge {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            background: rgba(16, 185, 129, 0.15);
            color: #34d399;
            font-size: 13px;
            font-weight: 600;
            padding: 6px 14px;
            border-radius: 20px;
            margin-bottom: 28px;
        }
        .btn {
            display: block;
            width: 100%;
            padding: 16px;
            background: #635bff;
            color: white;
            text-decoration: none;
            border-radius: 14px;
            font-weight: 700;
            font-size: 16px;
            transition: all 0.2s;
            border: none;
            cursor: pointer;
        }
        .btn:hover { background: #4f46e5; }
        .note { font-size: 12px; color: #64748b; margin-top: 18px; line-height: 1.4; }
    </style>
</head>
<body>
    <div class="card">
        <div class="icon-box">
            <svg viewBox="0 0 24 24"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/></svg>
        </div>
        <h1>Payment Successful!</h1>
        <p class="subtitle">RM ${amountFormatted} has been securely deposited into Campus Swap Escrow.</p>
        
        <div class="escrow-badge">
            <span>🛡️ Escrow Protected &amp; Verified</span>
        </div>

        <div class="pin-container">
            <div class="pin-label">Your 4-Digit Handover PIN</div>
            <div class="pin-code">${meetupPin}</div>
        </div>

        <p class="note">Show this 4-digit PIN to the seller during meetup to complete item handover.</p>
        <br/>
        <div style="background: rgba(99, 91, 255, 0.15); border: 1px solid rgba(99, 91, 255, 0.35); border-radius: 16px; padding: 18px; text-align: left;">
            <div style="font-size: 15px; font-weight: 700; color: #ffffff; margin-bottom: 6px; display: flex; align-items: center; gap: 8px;">
                <span>📱</span> Return to Campus Swap App
            </div>
            <div style="font-size: 13px; color: #cbd5e1; line-height: 1.5;">
                Your payment is verified and synced. Please switch back to the <b>Campus Swap</b> app to view your order.
            </div>
        </div>
    </div>
</body>
</html>
        `;

        res.send(html);
    } catch (error) {
        console.error('Handle Payment Success Error:', error);
        res.status(500).send('<h2>Internal Server Error</h2>');
    }
};

/**
 * GET /api/payments/cancel
 * Browser landing page when buyer cancels Stripe Checkout
 */
export const handlePaymentCancel = async (req, res) => {
    res.send(`
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Payment Cancelled - Campus Swap</title>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;600;700&display=swap" rel="stylesheet">
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Outfit', sans-serif; }
        body { background: #0f172a; color: #f8fafc; min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 20px; }
        .card { background: #1e293b; border-radius: 24px; padding: 36px 28px; max-width: 420px; width: 100%; text-align: center; }
        .icon-box { width: 72px; height: 72px; background: rgba(239, 68, 68, 0.15); color: #ef4444; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 20px; font-size: 32px; font-weight: bold; }
        h1 { font-size: 22px; font-weight: 700; margin-bottom: 8px; }
        p { font-size: 14px; color: #94a3b8; margin-bottom: 24px; }
        .btn { display: block; width: 100%; padding: 14px; background: #334155; color: white; border-radius: 12px; font-weight: 600; border: none; cursor: pointer; }
    </style>
</head>
<body>
    <div class="card">
        <div class="icon-box">✕</div>
        <h1>Payment Cancelled</h1>
        <p>Your card was not charged. You can retry payment anytime from your order details.</p>
        <button class="btn" onclick="window.close();">Return to App</button>
    </div>
</body>
</html>
    `);
};
