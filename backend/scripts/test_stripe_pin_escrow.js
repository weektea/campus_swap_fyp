import sequelize from '../src/config/database.js';
import { User, Product, Transaction } from '../src/models/index.js';
import { createCheckoutSession, confirmPayment, processStripeRefund } from '../src/controllers/paymentController.js';
import { verifyMeetupPin, getTransactionById, updateTransactionStatus } from '../src/controllers/transactionController.js';

async function runTests() {
    console.log('--- Starting Stripe Escrow & Meetup PIN Tests ---');
    try {
        await sequelize.authenticate();
        console.log('[OK] Database connected.');

        // 1. Find or create test buyer and seller
        let buyer = await User.findOne({ where: { role: 'student' } });
        let seller = await User.findOne({ where: { role: 'student', id: { [sequelize.Sequelize.Op.ne]: buyer.id } } });

        if (!buyer || !seller) {
            console.error('Test users not found');
            process.exit(1);
        }

        console.log(`[OK] Using Buyer: ${buyer.username} (${buyer.id}) | Seller: ${seller.username} (${seller.id})`);

        // 2. Create test product
        const product = await Product.create({
            seller_id: seller.id,
            title: 'Stripe Escrow Test Calculator',
            description: 'Scientific calculator for engineering students',
            price: 50.00,
            type: 'Sale',
            status: 'Available',
            category: 'Books & Study Materials',
            accepted_payment_methods: ['Cash', 'Stripe', 'Bank Transfer']
        });
        console.log(`[OK] Created Test Product #${product.id}`);

        // 3. Create test transaction in Scheduled status
        const tx = await Transaction.create({
            buyer_id: buyer.id,
            seller_id: seller.id,
            product_id: product.id,
            amount: 50.00,
            platform_fee: 1.00,
            status: 'Scheduled',
            selected_payment_method: 'Stripe',
            meetup_location: 'TAR UMT Library Lobby'
        });
        console.log(`[OK] Created Test Transaction #${tx.id} in 'Scheduled' state.`);

        // 4. Test Create Checkout Session
        const mockReqSession = {
            user: { id: buyer.id, email: buyer.email },
            body: { transaction_id: tx.id }
        };
        let sessionResData = null;
        const mockResSession = {
            status: (code) => ({
                json: (data) => {
                    sessionResData = data;
                    return data;
                }
            }),
            json: (data) => {
                sessionResData = data;
                return data;
            }
        };

        await createCheckoutSession(mockReqSession, mockResSession);
        console.log(`[OK] Stripe Checkout Session generated: URL = ${sessionResData.url}`);

        // 5. Test Confirm Payment (Generate PIN & Status -> To Confirm)
        const mockReqConfirm = {
            user: { id: buyer.id },
            body: { transaction_id: tx.id, session_id: sessionResData.session_id }
        };
        let confirmResData = null;
        const mockResConfirm = {
            status: (code) => ({
                json: (data) => {
                    confirmResData = data;
                    return data;
                }
            }),
            json: (data) => {
                confirmResData = data;
                return data;
            }
        };

        await confirmPayment(mockReqConfirm, mockResConfirm);
        console.log(`[OK] Payment Confirmed! Status = ${confirmResData.status}, Meetup PIN = ${confirmResData.meetup_pin}`);

        if (!confirmResData.meetup_pin || confirmResData.meetup_pin.length !== 4) {
            throw new Error(`Expected 4-digit PIN, got ${confirmResData.meetup_pin}`);
        }

        // 6. Test Security Masking
        // Seller Query
        let sellerViewData = null;
        const mockReqSellerView = { params: { id: tx.id }, user: { id: seller.id } };
        const mockResSellerView = {
            status: () => ({ json: (d) => { sellerViewData = d; } }),
            json: (d) => { sellerViewData = d; }
        };
        await getTransactionById(mockReqSellerView, mockResSellerView);
        if (sellerViewData.meetup_pin !== null) {
            throw new Error(`Security Failure: Seller was able to see meetup_pin (${sellerViewData.meetup_pin})!`);
        }
        console.log(`[OK] Security Masking Verified: Seller sees meetup_pin = null.`);

        // Buyer Query
        let buyerViewData = null;
        const mockReqBuyerView = { params: { id: tx.id }, user: { id: buyer.id } };
        const mockResBuyerView = {
            status: () => ({ json: (d) => { buyerViewData = d; } }),
            json: (d) => { buyerViewData = d; }
        };
        await getTransactionById(mockReqBuyerView, mockResBuyerView);
        if (buyerViewData.meetup_pin !== confirmResData.meetup_pin) {
            throw new Error(`Buyer failed to retrieve their meetup_pin!`);
        }
        console.log(`[OK] Security Masking Verified: Buyer sees their private meetup_pin = ${buyerViewData.meetup_pin}.`);

        // 7. Test PIN Verification Endpoint
        // A. Wrong PIN
        let wrongPinStatus = 200;
        let wrongPinError = null;
        const mockReqWrongPin = { params: { id: tx.id }, user: { id: seller.id }, body: { pin: '0000' } };
        const mockResWrongPin = {
            status: (code) => {
                wrongPinStatus = code;
                return { json: (d) => { wrongPinError = d; } };
            },
            json: (d) => { wrongPinError = d; }
        };
        await verifyMeetupPin(mockReqWrongPin, mockResWrongPin);
        if (wrongPinStatus !== 400) {
            throw new Error(`Expected 400 for wrong PIN, got ${wrongPinStatus}`);
        }
        console.log(`[OK] Wrong PIN rejected as expected with error: "${wrongPinError?.error}"`);

        // B. Correct PIN
        let verifyPinStatus = 200;
        let verifyPinData = null;
        const mockReqCorrectPin = { params: { id: tx.id }, user: { id: seller.id }, body: { pin: confirmResData.meetup_pin } };
        const mockResCorrectPin = {
            status: (code) => {
                verifyPinStatus = code;
                return { json: (d) => { verifyPinData = d; } };
            },
            json: (d) => { verifyPinData = d; }
        };
        await verifyMeetupPin(mockReqCorrectPin, mockResCorrectPin);
        if (verifyPinStatus !== 200 || verifyPinData.transaction.status !== 'Completed') {
            throw new Error(`Failed to complete transaction with correct PIN.`);
        }
        console.log(`[OK] Correct PIN accepted! Order #${tx.id} completed. Product status: Sold.`);

        // 8. Test Cancellation & Auto-Refund (Unhappy Path)
        console.log('--- Testing Cancellation & Stripe Auto-Refund ---');
        const txRefund = await Transaction.create({
            buyer_id: buyer.id,
            seller_id: seller.id,
            product_id: product.id,
            amount: 30.00,
            platform_fee: 0.60,
            status: 'To Confirm',
            selected_payment_method: 'Stripe',
            stripe_payment_intent_id: 'pi_test_mock_for_cancellation_refund',
            stripe_payment_status: 'paid',
            meetup_pin: '5678'
        });

        const mockReqCancel = {
            params: { id: txRefund.id },
            user: { id: buyer.id },
            body: { status: 'Cancelled', cancellation_reason: 'Buyer had to travel, requested refund' }
        };
        let cancelResData = null;
        const mockResCancel = {
            status: (code) => ({ json: (d) => { cancelResData = d; } }),
            json: (d) => { cancelResData = d; }
        };
        await updateTransactionStatus(mockReqCancel, mockResCancel);
        await txRefund.reload();

        if (txRefund.status !== 'Cancelled' || txRefund.stripe_payment_status !== 'refunded') {
            throw new Error(`Auto-refund on cancellation failed. Status=${txRefund.status}, stripe_payment_status=${txRefund.stripe_payment_status}`);
        }
        console.log(`[OK] Order cancelled and Stripe Escrow auto-refunded successfully! Status = ${txRefund.status}, stripe_payment_status = ${txRefund.stripe_payment_status}`);

        // Cleanup test product & transactions
        await tx.destroy().catch(() => {});
        await txRefund.destroy().catch(() => {});
        await product.destroy().catch(() => {});

        console.log('\n========================================');
        console.log('ALL STRIPE & MEETUP PIN TESTS PASSED! 🎉');
        console.log('========================================\n');
        process.exit(0);
    } catch (e) {
        console.error('Test Failed:', e);
        process.exit(1);
    }
}

runTests();
