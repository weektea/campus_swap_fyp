import { Transaction, Product, User } from '../src/models/index.js';
import sequelize from '../src/config/database.js';
import { createCheckoutSession, processStripeRefund } from '../src/controllers/paymentController.js';
import { returnRentalAndRefundDeposit, verifyMeetupPin } from '../src/controllers/transactionController.js';

async function runTests() {
    console.log('--- Starting Rental Stripe Deposit & Smart Platform Fee Tests ---');
    try {
        await sequelize.authenticate();
        console.log('[OK] Database connected.');

        // 1. Get or create test buyer and seller
        let buyer = await User.findOne({ where: { role: 'student' } });
        let seller = await User.findOne({ where: { role: 'student', id: { [sequelize.Sequelize.Op.ne]: buyer.id } } });

        if (!buyer || !seller) {
            console.error('Need at least 2 users in database.');
            process.exit(1);
        }

        console.log(`[OK] Buyer: ${buyer.username} (initial balance due: RM ${buyer.accumulated_balance_due}) | Seller: ${seller.username} (initial balance due: RM ${seller.accumulated_balance_due})`);

        // Record initial seller balance due
        const initialSellerBalance = parseFloat(seller.accumulated_balance_due || 0);

        // 2. Create a Rental Product
        const rentalProduct = await Product.create({
            title: 'Test Sony Alpha Camera (Rental Test)',
            description: 'Test camera for rental deposit workflow',
            price: 50.00,
            type: 'Rent',
            rental_price_per_day: 50.00,
            rental_deposit: 100.00,
            status: 'Available',
            seller_id: seller.id
        });
        console.log(`[OK] Created Rental Product #${rentalProduct.id} (Price/Day: RM 50, Deposit: RM 100)`);

        // -------------------------------------------------------------
        // TEST CASE 1: Rental Stripe Checkout & Capture
        // -------------------------------------------------------------
        console.log('\n--- Test 1: Rental Stripe Checkout Session ---');
        // Total = 3 days * RM 50 (RM 150) + RM 100 deposit = RM 250
        const startDate = new Date();
        startDate.setDate(startDate.getDate() + 1);
        const endDate = new Date();
        endDate.setDate(endDate.getDate() + 4);

        const rentTransaction = await Transaction.create({
            buyer_id: buyer.id,
            seller_id: seller.id,
            product_id: rentalProduct.id,
            amount: 250.00,
            deposit_amount: 100.00,
            deposit_status: 'Held',
            rental_start_date: startDate,
            rental_end_date: endDate,
            rental_type: 'Short-term',
            selected_payment_method: 'Stripe',
            stripe_payment_intent_id: 'pi_test_rental_deposit_mock',
            status: 'Scheduled'
        });

        const reqMock = { body: { transaction_id: rentTransaction.id }, user: { id: buyer.id, email: buyer.email } };
        let sessionData = null;
        const resMock = {
            json: (data) => { sessionData = data; },
            status: (code) => ({ json: (err) => console.log('Error in checkout session:', code, err) })
        };
        await createCheckoutSession(reqMock, resMock);
        console.log(`[OK] Checkout session generated for Rental: Total = RM ${sessionData.amount}`);
        if (sessionData.amount !== 250) {
            throw new Error(`Expected checkout amount to be 250, got ${sessionData.amount}`);
        }

        // Simulate payment completion & PIN generation
        rentTransaction.status = 'To Confirm';
        rentTransaction.meetup_pin = '3891';
        rentTransaction.stripe_payment_status = 'paid';
        await rentTransaction.save();

        // -------------------------------------------------------------
        // TEST CASE 2: Handover PIN verification moves rental to 'On Rent'
        // -------------------------------------------------------------
        console.log('\n--- Test 2: Meetup PIN Verification for Rental Handover ---');
        let pinRes = null;
        await verifyMeetupPin(
            { params: { id: rentTransaction.id }, body: { pin: '3891' }, user: { id: seller.id, role: 'student' } },
            { 
                json: (data) => { pinRes = data; },
                status: (code) => ({ json: (err) => { console.error('PIN Error:', code, err); } })
            }
        );
        await rentTransaction.reload();
        console.log(`[OK] Rental order status after PIN verification: ${rentTransaction.status} (Expected: 'On Rent')`);
        if (rentTransaction.status !== 'On Rent') {
            throw new Error(`Expected status 'On Rent', got '${rentTransaction.status}'`);
        }

        // -------------------------------------------------------------
        // TEST CASE 3: Clean Return with Full Deposit Refund via Stripe
        // -------------------------------------------------------------
        console.log('\n--- Test 3: Clean Rental Return with Stripe Full Deposit Refund ---');
        let returnRes = null;
        await returnRentalAndRefundDeposit(
            { params: { id: rentTransaction.id }, user: { id: seller.id, role: 'student' } },
            { 
                json: (data) => { returnRes = data; },
                status: (code) => ({ json: (err) => { console.error('Return Error:', code, err); } })
            }
        );

        await rentTransaction.reload();
        await rentalProduct.reload();
        console.log(`[OK] Order Status: ${rentTransaction.status}, Deposit Status: ${rentTransaction.deposit_status}, Net Refund: RM ${returnRes.net_refund}`);
        console.log(`[OK] Product Status reverted to: ${rentalProduct.status}`);

        if (rentTransaction.deposit_status !== 'Refunded') {
            throw new Error(`Expected deposit_status 'Refunded', got '${rentTransaction.deposit_status}'`);
        }
        if (returnRes.net_refund !== 100) {
            throw new Error(`Expected net_refund to be 100, got ${returnRes.net_refund}`);
        }
        if (rentalProduct.status !== 'Available') {
            throw new Error(`Expected product status 'Available', got '${rentalProduct.status}'`);
        }

        // Verify Platform Fee was calculated strictly on Rental Fee (RM 150 * 0.02 = RM 3.00)
        console.log(`[OK] Platform Fee: RM ${rentTransaction.platform_fee} (Expected RM 3.00 on net rent of RM 150)`);
        if (parseFloat(rentTransaction.platform_fee) !== 3.00) {
            throw new Error(`Expected platform_fee to be 3.00, got ${rentTransaction.platform_fee}`);
        }

        // Verify Smart Platform Fee Accumulation for Stripe:
        // Seller balance due MUST NOT change because Stripe handled payment online!
        await seller.reload();
        const sellerBalanceAfterStripe = parseFloat(seller.accumulated_balance_due || 0);
        console.log(`[OK] Seller balance due after Stripe rental completion: RM ${sellerBalanceAfterStripe} (Unchanged: ${sellerBalanceAfterStripe === initialSellerBalance})`);
        if (sellerBalanceAfterStripe !== initialSellerBalance) {
            throw new Error(`Stripe transaction should NOT add to accumulated_balance_due. Expected ${initialSellerBalance}, got ${sellerBalanceAfterStripe}`);
        }

        // -------------------------------------------------------------
        // TEST CASE 4: Late Return with Partial Deposit Refund
        // -------------------------------------------------------------
        console.log('\n--- Test 4: Late Rental Return (Penalty & Partial Deposit Refund) ---');
        const pastStart = new Date();
        pastStart.setDate(pastStart.getDate() - 10);
        const pastEnd = new Date();
        pastEnd.setDate(pastEnd.getDate() - 1); // 1 day late

        const lateRentTx = await Transaction.create({
            buyer_id: buyer.id,
            seller_id: seller.id,
            product_id: rentalProduct.id,
            amount: 250.00,
            deposit_amount: 100.00,
            deposit_status: 'Held',
            rental_start_date: pastStart,
            rental_end_date: pastEnd,
            rental_type: 'Short-term',
            selected_payment_method: 'Stripe',
            stripe_payment_intent_id: 'pi_test_rental_late_deposit_mock',
            status: 'On Rent'
        });

        let lateReturnRes = null;
        await returnRentalAndRefundDeposit(
            { params: { id: lateRentTx.id }, user: { id: seller.id, role: 'student' } },
            { 
                json: (data) => { lateReturnRes = data; },
                status: (code) => ({ json: (err) => { console.error('Late Return Error:', code, err); } })
            }
        );

        await lateRentTx.reload();
        console.log(`[OK] Late Return Result: Penalty = RM ${lateReturnRes.penalty}, Net Refund = RM ${lateReturnRes.net_refund}, Deposit Status = ${lateRentTx.deposit_status}`);
        if (lateRentTx.deposit_status !== 'Partially_Refunded') {
            throw new Error(`Expected deposit_status 'Partially_Refunded', got '${lateRentTx.deposit_status}'`);
        }
        if (lateReturnRes.penalty !== 50 || lateReturnRes.net_refund !== 50) {
            throw new Error(`Expected penalty=50 and net_refund=50 for 1-day late return of RM 50/day`);
        }

        // -------------------------------------------------------------
        // TEST CASE 5: Cash Transaction MUST Add 2% to accumulated_balance_due
        // -------------------------------------------------------------
        console.log('\n--- Test 5: Cash Transaction Platform Fee Accumulator ---');
        const cashProduct = await Product.create({
            title: 'Test Cash Sale Textbook',
            description: 'Cash sale item test',
            price: 100.00,
            type: 'Sale',
            status: 'Available',
            seller_id: seller.id
        });

        const cashTx = await Transaction.create({
            buyer_id: buyer.id,
            seller_id: seller.id,
            product_id: cashProduct.id,
            amount: 100.00,
            selected_payment_method: 'Cash',
            status: 'Scheduled'
        });

        // Buyer uploads proof -> To Confirm
        cashTx.status = 'To Confirm';
        await cashTx.save();

        // Seller confirms cash received & completes
        const { updateTransactionStatus } = await import('../src/controllers/transactionController.js');
        await updateTransactionStatus(
            { params: { id: cashTx.id }, body: { status: 'Completed' }, user: { id: seller.id, role: 'student' } },
            { 
                json: (data) => console.log('[OK] Cash transaction completed successfully.'),
                status: (code) => ({ json: (err) => console.error('Cash error:', code, err) })
            }
        );

        await seller.reload();
        const expectedCashBalance = parseFloat((sellerBalanceAfterStripe + 2.00).toFixed(2)); // RM 100 * 2% = RM 2.00
        const currentSellerBalance = parseFloat(seller.accumulated_balance_due);
        console.log(`[OK] Seller accumulated_balance_due after Cash transaction: RM ${currentSellerBalance} (Expected: RM ${expectedCashBalance})`);
        if (currentSellerBalance !== expectedCashBalance) {
            throw new Error(`Expected seller accumulated_balance_due to be ${expectedCashBalance}, got ${currentSellerBalance}`);
        }

        // -------------------------------------------------------------
        // TEST CASE 6: Rental Overlapping Date Auto-Cancellation on Accept
        // -------------------------------------------------------------
        console.log('\n--- Test 6: Rental Overlapping Date Auto-Cancellation on Accept ---');
        const overlapRentalProduct = await Product.create({
            title: 'Test Overlap Camera (Rent Test)',
            description: 'Item for multi-buyer overlap test',
            price: 40.00,
            type: 'Rent',
            rental_price_per_day: 40.00,
            rental_deposit: 80.00,
            status: 'Available',
            seller_id: seller.id
        });

        const overlapStart = new Date();
        overlapStart.setDate(overlapStart.getDate() + 5);
        const overlapEnd = new Date();
        overlapEnd.setDate(overlapEnd.getDate() + 8);

        // Buyer A requests dates (Day 5 to Day 8)
        const orderA = await Transaction.create({
            buyer_id: buyer.id,
            seller_id: seller.id,
            product_id: overlapRentalProduct.id,
            amount: 200.00,
            deposit_amount: 80.00,
            rental_start_date: overlapStart,
            rental_end_date: overlapEnd,
            rental_type: 'Short-term',
            selected_payment_method: 'Cash',
            status: 'Pending'
        });

        // Buyer B requests overlapping dates (Day 6 to Day 10)
        const orderB = await Transaction.create({
            buyer_id: buyer.id,
            seller_id: seller.id,
            product_id: overlapRentalProduct.id,
            amount: 240.00,
            deposit_amount: 80.00,
            rental_start_date: new Date(overlapStart.getTime() + 86400000), // Day 6
            rental_end_date: new Date(overlapEnd.getTime() + 86400000 * 2), // Day 10
            rental_type: 'Short-term',
            selected_payment_method: 'Cash',
            status: 'Pending'
        });

        // Seller accepts Order A -> Order A becomes 'Scheduled'
        await updateTransactionStatus(
            { params: { id: orderA.id }, body: { status: 'Scheduled' }, user: { id: seller.id, role: 'student' } },
            { 
                json: (data) => console.log('[OK] Seller accepted Order A -> Status: Scheduled'),
                status: (code) => ({ json: (err) => console.error('Accept error:', code, err) })
            }
        );

        await orderA.reload();
        await orderB.reload();

        console.log(`[OK] Order A status: ${orderA.status} (Expected: 'Scheduled')`);
        console.log(`[OK] Order B status: ${orderB.status} (Expected: 'Cancelled')`);
        console.log(`[OK] Order B cancellation reason: "${orderB.cancellation_reason}"`);

        if (orderA.status !== 'Scheduled') {
            throw new Error(`Expected Order A to be 'Scheduled', got '${orderA.status}'`);
        }
        if (orderB.status !== 'Cancelled') {
            throw new Error(`Expected Order B to be auto-cancelled with date overlap, got '${orderB.status}'`);
        }

        // Cleanup test products & transactions
        await rentTransaction.destroy();
        await lateRentTx.destroy();
        await cashTx.destroy();
        await orderA.destroy();
        await orderB.destroy();
        await rentalProduct.destroy();
        await cashProduct.destroy();
        await overlapRentalProduct.destroy();

        console.log('\n======================================================');
        console.log('ALL RENTAL STRIPE DEPOSIT & FEE ACCUMULATOR TESTS PASSED! 🎉');
        console.log('======================================================\n');
        process.exit(0);

    } catch (err) {
        console.error('\n❌ Test Failed:', err);
        process.exit(1);
    }
}

runTests();
