import { Transaction, Product, User, Review, Category, SubCategory, Dispute, UserInteraction, ActivityLog } from '../models/index.js';
import { Op } from 'sequelize';
import { createNotification } from './notificationController.js';
import { emitToUser, emitToAdmins } from '../config/socket.js';
import { sendError, isStaff } from '../middleware/authMiddleware.js';

export const createTransaction = async (req, res) => {
    try {
        const { buyer_id, seller_id, product_id, meetup_location, scheduled_at, selected_payment_method } = req.body;
        let amount = req.body.amount;

        // Validate
        if (!buyer_id || !seller_id || !product_id || amount === undefined || amount === null) {
            return res.status(400).json({ error: 'Missing required transaction details' });
        }
        if (!selected_payment_method) {
            return res.status(400).json({ error: 'Selected payment method is required' });
        }

        // Check Product Availability
        const product = await Product.findByPk(product_id);
        if (!product) {
            return res.status(404).json({ error: 'Product not found' });
        }
        if (product.status !== 'Available') {
            return res.status(409).json({ error: 'Conflict Detected: Item already reserved' });
        }

        // Fix 1: Prevent self-trading
        if (String(buyer_id) === String(product.seller_id)) {
            try {
                await ActivityLog.create({
                    user_id: buyer_id,
                    action: 'ANOMALY: Self-trading block'
                });
            } catch (err) {
                console.error("Failed to log self-trading anomaly:", err);
            }
            return sendError(res, 400, 'Self-trading is prohibited. You cannot purchase or rent your own product listing.');
        }

        // Validate selected payment method
        let acceptedMethods = product.accepted_payment_methods;
        if (typeof acceptedMethods === 'string') {
            try {
                acceptedMethods = JSON.parse(acceptedMethods);
            } catch (e) {
                acceptedMethods = ['Cash', 'TNG', 'Bank Transfer'];
            }
        }
        if (!Array.isArray(acceptedMethods)) {
            acceptedMethods = ['Cash', 'TNG', 'Bank Transfer'];
        }
        if (!acceptedMethods.includes(selected_payment_method)) {
            return res.status(400).json({ error: `Selected payment method is not accepted by the seller. Accepted methods: ${acceptedMethods.join(', ')}` });
        }

        // UC17 Rental Constraints
        let { rental_start_date, rental_end_date, co_renter_username } = req.body;
        let rentType = 'Short-term';
        let grpSize = 1;
        let coRenterId = null;
        let depositAmount = 0.0;
        let depositStatus = 'Waived';

        if (product.type === 'Rent') {
            if (!rental_start_date || !rental_end_date) {
                return res.status(400).json({ error: 'Rental start and end dates are required for this product.' });
            }
            const startDate = new Date(rental_start_date);
            const endDate = new Date(rental_end_date);
            
            // Validations & Foolproofing
            const today = new Date();
            today.setHours(0, 0, 0, 0);

            if (startDate < today) {
                return res.status(400).json({ error: 'Rental start date cannot be in the past.' });
            }
            if (endDate < startDate) {
                return res.status(400).json({ error: 'Rental end date cannot be before the start date.' });
            }

            // Date-Range Overlap Conflict Detection with confirmed active rental bookings
            const overlappingTx = await Transaction.findOne({
                where: {
                    product_id,
                    status: ['Scheduled', 'To Confirm', 'On Rent'],
                    rental_start_date: { [Op.lte]: endDate },
                    rental_end_date: { [Op.gte]: startDate }
                }
            });

            if (overlappingTx) {
                return res.status(409).json({
                    error: 'Conflict Detected: The item is already booked for the selected date range. Please select different dates.'
                });
            }

            const diffTime = endDate.getTime() - startDate.getTime();
            const rentalDays = Math.max(1, Math.ceil(diffTime / (1000 * 60 * 60 * 24)) + 1);
            
            if (product.max_rental_duration && rentalDays > product.max_rental_duration) {
                return res.status(400).json({ error: `Cannot exceed maximum rental duration of ${product.max_rental_duration} days.` });
            }

            let subtotal = rentalDays * parseFloat(product.rental_price_per_day || product.price);

            // 1. Long-term check: 30 days or more
            if (rentalDays >= 30) {
                rentType = 'Long-term';
                subtotal = subtotal * 0.7; // flat 30% Academic Discount
            }

            // 2. Shared Rental check
            if (co_renter_username && co_renter_username.trim()) {
                const cleanUsername = co_renter_username.trim();
                const coRenter = await User.findOne({ where: { username: cleanUsername } });
                if (!coRenter) {
                    return res.status(400).json({ error: `Co-renter username '${cleanUsername}' not found.` });
                }

                // Verify co-renter is not the buyer themselves
                if (coRenter.id === buyer_id) {
                    return res.status(400).json({ error: 'You cannot share a rental with yourself.' });
                }

                rentType = 'Shared';
                grpSize = 2;
                coRenterId = coRenter.id;
            }

            const buyer = await User.findByPk(buyer_id);
            let deposit = product.rental_deposit ? parseFloat(product.rental_deposit) : 0.0;
            if (buyer && parseFloat(buyer.reputation_score || 5.0) >= 4.8) {
                deposit = 0.0;
                depositStatus = 'Waived';
            } else {
                depositStatus = deposit > 0 ? 'Held' : 'Waived';
            }
            depositAmount = deposit;

            // Shared logic: Only split rental fee (subtotal), hold full deposit
            let finalAmount = 0.0;
            if (rentType === 'Shared') {
                finalAmount = (subtotal / 2.0) + deposit;
            } else {
                finalAmount = subtotal + deposit;
            }

            amount = finalAmount.toFixed(2);
        }

        // Calculate 2% Platform Fee (Differentiate SALE vs RENT)

        const totalAmount = parseFloat(amount);
        let rentalFee = totalAmount;
        let platformFee = 0.0;

        if (product.type === 'Rent') {
            rentalFee = Math.max(0, totalAmount - depositAmount);
            platformFee = parseFloat((rentalFee * 0.02).toFixed(2));
        } else {
            rentalFee = totalAmount;
            platformFee = parseFloat((totalAmount * 0.02).toFixed(2));
        }

        // Create Transaction
        const transaction = await Transaction.create({
            buyer_id,
            seller_id,
            product_id,
            amount: totalAmount.toFixed(2),
            platform_fee: platformFee.toFixed(2),
            meetup_location,
            scheduled_at,
            rental_start_date,
            rental_end_date,
            status: 'Pending',
            selected_payment_method,
            rental_type: rentType,
            group_size: grpSize,
            co_renter_id: coRenterId,
            deposit_amount: depositAmount.toFixed(2),
            deposit_status: depositStatus
        });

        // Notify Seller
        await createNotification(
            seller_id,
            product.type === 'Rent' ? 'New Rental Request' : 'New Purchase Request',
            `A student wants to ${product.type === 'Rent' ? 'rent' : 'buy'} your item for RM ${amount}.`,
            'Transaction',
            transaction.id
        );

        // Real-time socket update for buyer & seller order lists
        emitToUser(buyer_id, 'transaction_status_updated', { transaction_id: transaction.id, status: 'Pending' });
        emitToUser(seller_id, 'transaction_status_updated', { transaction_id: transaction.id, status: 'Pending' });

        const resObj = transaction.toJSON();
        const sellerNetEarnings = parseFloat((rentalFee - platformFee).toFixed(2));
        resObj.rental_fee = rentalFee;
        resObj.deposit_amount = depositAmount;
        resObj.item_price = rentalFee;
        resObj.platform_fee = platformFee;
        resObj.total_amount_paid_by_buyer = totalAmount;
        resObj.seller_net_earnings = sellerNetEarnings;
        resObj.total_payment = totalAmount;

        res.status(201).json(resObj);
    } catch (error) {
        console.error('Create Transaction Error:', error);
        res.status(500).json({ error: 'Failed to create transaction' });
    }
};

export const getUserTransactions = async (req, res) => {
    try {
        const { user_id } = req.params;
        const { type } = req.query; // 'buying' or 'selling'

        // Fix 2: Access Control guard
        if (String(req.user.id) !== String(user_id) && !isStaff(req.user)) {
            return sendError(res, 403, 'Access Denied: You are not authorized to view these transactions.');
        }

        const whereClause = type === 'selling'
            ? { seller_id: user_id }
            : { buyer_id: user_id };

        const transactions = await Transaction.findAll({
            where: whereClause,
            include: [
                { model: Product, as: 'product' },
                { model: User, as: 'buyer', attributes: ['id', 'username', 'full_name', 'email', 'profile_image_url'] },
                { model: User, as: 'seller', attributes: ['id', 'username', 'full_name', 'email', 'profile_image_url'] },
                { model: Review, as: 'reviews', required: false }
            ],
            order: [['createdAt', 'DESC']]
        });
        const maskedTransactions = transactions.map(tx => {
            const txObj = tx.toJSON();
            
            const totalAmount = parseFloat(txObj.amount || 0);
            const depositVal = txObj.deposit_amount ? parseFloat(txObj.deposit_amount) : 0.0;
            const isRent = txObj.product?.type === 'Rent' || txObj.rental_start_date != null;
            const rentalFee = isRent ? Math.max(0, totalAmount - depositVal) : totalAmount;

            // Read stored platform_fee directly from DB to preserve historical integrity
            const platformFee = txObj.platform_fee !== undefined && txObj.platform_fee !== null
                ? parseFloat(txObj.platform_fee)
                : parseFloat((rentalFee * 0.02).toFixed(2));
            const sellerNetEarnings = parseFloat((rentalFee - platformFee).toFixed(2));

            txObj.rental_fee = rentalFee;
            txObj.deposit_amount = depositVal;
            txObj.item_price = rentalFee;
            txObj.platform_fee = platformFee;
            txObj.total_amount_paid_by_buyer = totalAmount;
            txObj.seller_net_earnings = sellerNetEarnings;
            txObj.total_payment = totalAmount;

            // Filter reviews in memory to match reviewer_id = user_id (avoid Sequelize query filtering gotcha)
            if (txObj.reviews) {
                txObj.reviews = txObj.reviews.filter(r => String(r.reviewer_id) === String(user_id));
            }

            if (txObj.review_status !== 'PUBLISHED') {
                if (type === 'buying') {
                    txObj.rating_from_seller = null;
                    txObj.seller_comment = "Awaiting the other party to submit their review to unlock.";
                } else if (type === 'selling') {
                    txObj.rating_from_buyer = null;
                    txObj.buyer_comment = "Awaiting the other party to submit their review to unlock.";
                }
            }
            return txObj;
        });

        res.json(maskedTransactions);
    } catch (error) {
        console.error('Get Transactions Error:', error);
        res.status(500).json({ error: 'Failed to fetch transactions' });
    }
};

export const getTransactionById = async (req, res) => {
    try {
        const { id } = req.params;
        const transaction = await Transaction.findByPk(id, {
            include: [
                { model: Product, as: 'product' },
                { model: User, as: 'buyer', attributes: ['id', 'username', 'full_name', 'email', 'profile_image_url'] },
                { model: User, as: 'seller', attributes: ['id', 'username', 'full_name', 'email', 'profile_image_url'] },
                { model: Review, as: 'reviews', required: false }
            ]
        });

        if (!transaction) return res.status(404).json({ error: 'Transaction not found' });

        // Security check (use string comparison for UUID/int compatibility)
        const reqUserId = String(req.user.id);
        if (reqUserId !== String(transaction.buyer_id) && reqUserId !== String(transaction.seller_id)) {
             return res.status(403).json({ error: 'Not authorized to view this transaction' });
        }

        const txObj = transaction.toJSON();
        const totalAmount = parseFloat(txObj.amount || 0);
        const depositVal = txObj.deposit_amount ? parseFloat(txObj.deposit_amount) : 0.0;
        const isRent = txObj.product?.type === 'Rent' || txObj.rental_start_date != null;
        const rentalFee = isRent ? Math.max(0, totalAmount - depositVal) : totalAmount;

        // Read stored platform_fee directly from DB
        const platformFee = txObj.platform_fee !== undefined && txObj.platform_fee !== null
            ? parseFloat(txObj.platform_fee)
            : parseFloat((rentalFee * 0.02).toFixed(2));
        const sellerNetEarnings = parseFloat((rentalFee - platformFee).toFixed(2));

        txObj.rental_fee = rentalFee;
        txObj.deposit_amount = depositVal;
        txObj.item_price = rentalFee;
        txObj.platform_fee = platformFee;
        txObj.total_amount_paid_by_buyer = totalAmount;
        txObj.seller_net_earnings = sellerNetEarnings;
        txObj.total_payment = totalAmount;

        if (txObj.review_status !== 'PUBLISHED') {
            if (reqUserId === String(txObj.buyer_id)) {
                txObj.rating_from_seller = null;
                txObj.seller_comment = "Awaiting the other party to submit their review to unlock.";
                if (txObj.reviews) {
                    txObj.reviews = txObj.reviews.filter(r => String(r.reviewer_id) === reqUserId);
                }
            } else if (reqUserId === String(txObj.seller_id)) {
                txObj.rating_from_buyer = null;
                txObj.buyer_comment = "Awaiting the other party to submit their review to unlock.";
                if (txObj.reviews) {
                    txObj.reviews = txObj.reviews.filter(r => String(r.reviewer_id) === reqUserId);
                }
            }
        }

        res.json(txObj);
    } catch (error) {
        console.error('Get Transaction By ID Error:', error);
        res.status(500).json({ error: 'Failed to fetch transaction details' });
    }
};

const CARBON_SAVINGS = {
    // 1. Electronics & Gadgets
    'Audio': 15.0,
    'Laptops': 250.0,
    'PC Accessories': 10.0,
    'Smartphones': 65.0,
    'Tablets': 110.0,
    'Electronics_Others': 50.0,
    'Electronics & Gadgets': 55.5,
    
    // 2. Fashion & Accessories
    'Bags & Luggage': 20.0,
    'Clothing': 15.0,
    'Fashion Accessories': 5.0,
    'Shoes': 15.0,
    'Fashion & Accessories': 8.2,
    
    // 3. Furniture & Appliances
    'Appliances': 80.0,
    'Chairs': 35.0,
    'Sofas': 150.0,
    'Storage': 50.0,
    'Tables & Desks': 60.0,
    'Furniture_Others': 40.0,
    'Furniture & Appliances': 30.0,
    
    // 4. Books & Study Materials
    'Books': 2.5,
    'Calculators': 8.0,
    'Notes & Past Papers': 1.5,
    'Books_Others': 2.0,
    'Books & Study Materials': 3.5,
    
    // 5. Sports
    'Apparel': 10.0,
    'Bicycles': 120.0,
    'Equipment': 20.0,
    'Sports_Others': 15.0,
    'Sports': 15.0,
    
    // 6. Stationery
    'Art Supplies': 3.0,
    'Paper': 5.0,
    'Writing': 0.5,
    'Stationery_Others': 2.0,
    'Stationery': 2.0,
    
    // 7. Others
    'Cosmetics & Beauty': 2.0,
    'Drinkware': 5.0,
    'Miscellaneous': 5.0,
    'Others': 10.0
};

export const getCarbonValue = (category, subCategory, product = null) => {
    // Try database factors first
    if (product) {
        if (product.subcategoryModel && product.subcategoryModel.carbon_conversion_factor !== undefined && product.subcategoryModel.carbon_conversion_factor !== null) {
            const factor = parseFloat(product.subcategoryModel.carbon_conversion_factor);
            if (factor > 0) return factor;
        }
        if (product.categoryModel && product.categoryModel.carbon_conversion_factor !== undefined && product.categoryModel.carbon_conversion_factor !== null) {
            const factor = parseFloat(product.categoryModel.carbon_conversion_factor);
            if (factor > 0) return factor;
        }
    }

    if (subCategory && CARBON_SAVINGS[subCategory] !== undefined) {
        return CARBON_SAVINGS[subCategory];
    }
    
    // Fallback based on category name
    if (category && CARBON_SAVINGS[category] !== undefined) {
        return CARBON_SAVINGS[category];
    }
    
    // Legacy category maps
    const categoryMapping = {
        'Books': 'Books_Others',
        'Electronics': 'Electronics_Others',
        'Fashion': 'Fashion & Accessories',
        'Furniture': 'Furniture_Others',
        'Stationery': 'Stationery_Others',
        'Sports': 'Sports_Others',
        'Clothing & Fashion': 'Fashion & Accessories',
        'Textbooks & Stationery': 'Books & Study Materials',
        'Vehicles': 'Sports_Others'
    };
    
    if (category && categoryMapping[category]) {
        const mappedCat = categoryMapping[category];
        if (CARBON_SAVINGS[mappedCat] !== undefined) {
            return CARBON_SAVINGS[mappedCat];
        }
    }
    
    return 2.5; // Absolute Fallback
};

export const updateTransactionStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { status, cancellation_reason } = req.body; // 'Completed', 'Cancelled', 'Scheduled'

        const transaction = await Transaction.findByPk(id);
        if (!transaction) {
            return res.status(404).json({ error: 'Transaction not found' });
        }

        const oldStatus = transaction.status;

        // Fetch product with categories early to fix undefined product bug and support intercept
        const product = await Product.findByPk(transaction.product_id, {
            include: [
                { model: Category, as: 'categoryModel' },
                { model: SubCategory, as: 'subcategoryModel' }
            ]
        });

        // Intercept Completed requested for a Rent item in To Confirm or Scheduled status -> Set target status to 'On Rent'
        let targetStatus = status;
        if (targetStatus === 'Completed' && (oldStatus === 'To Confirm' || oldStatus === 'Scheduled') && product && product.type === 'Rent') {
            targetStatus = 'On Rent';
        }

        // State Machine Validation
        const validTransitions = {
            'Pending': ['Scheduled', 'Cancelled'],
            'Scheduled': ['To Confirm', 'Completed', 'Cancelled'],
            'To Confirm': ['On Rent', 'Completed', 'Cancelled', 'Disputed'],
            'On Rent': ['Completed', 'Disputed'],
            'Completed': [],
            'Cancelled': [],
            'Disputed': []
        };

        if (oldStatus === 'Cancelled') {
            return res.status(400).json({ error: 'This transaction has already been cancelled.' });
        }

        if (oldStatus === 'Completed') {
            return res.status(400).json({ error: 'This transaction has already been completed.' });
        }

        if (!validTransitions[oldStatus] || !validTransitions[oldStatus].includes(targetStatus)) {
            return res.status(400).json({ error: `Invalid transition from ${oldStatus} to ${targetStatus}` });
        }

        const requesterId = req.user?.id;
        const otherPartyId = String(requesterId) === String(transaction.buyer_id) ? transaction.seller_id : transaction.buyer_id;

        // Prevent buyer from cancelling after submitting payment proof (To Confirm status)
        if (oldStatus === 'To Confirm' && targetStatus === 'Cancelled' && String(requesterId) === String(transaction.buyer_id)) {
            return res.status(400).json({ error: 'Payment receipt has been submitted. Order cannot be cancelled by buyer.' });
        }

        const updatePayload = { status: targetStatus };

        if (req.body.payment_proof_url) {
            updatePayload.payment_proof_url = req.body.payment_proof_url;
        }
        if (targetStatus === 'Cancelled') {
            if (requesterId) updatePayload.cancelled_by_id = requesterId;
            if (cancellation_reason) updatePayload.cancellation_reason = cancellation_reason;
        }

        // Atomic status update to prevent race conditions (double clicks)
        const [affectedRows] = await Transaction.update(
            updatePayload,
            { where: { id: id, status: oldStatus } }
        );

        if (affectedRows === 0) {
            return res.status(409).json({ error: 'Transaction status has already been updated.' });
        }

        // Reload to sync the instance in memory for subsequent operations
        await transaction.reload();

        // If completed, mark product as Sold or Available (for Rent)
        if (targetStatus === 'Completed') {
            if (product && product.type === 'Rent') {
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

            // Log transaction completion for both seller and buyer
            try {
                await ActivityLog.create({
                    user_id: transaction.seller_id,
                    action: 'ITEM_SOLD'
                });
                await ActivityLog.create({
                    user_id: transaction.buyer_id,
                    action: 'ITEM_BOUGHT'
                });
            } catch (e) {
                console.error("Failed to log transaction completion:", e.message);
            }
            
            // Deposit Management Lifecycle: when status changes to Completed (meaning item is returned safely),
            // the rental_deposit is marked for refund to the Buyer, while the rental fee goes to the Seller.
            let lateMessage = '';
            if (product && product.type === 'Rent') {
                const deposit = product.rental_deposit ? parseFloat(product.rental_deposit) : 0.0;
                
                // Late Return Check
                const endDate = new Date(transaction.rental_end_date);
                const today = new Date();
                today.setHours(0,0,0,0);
                endDate.setHours(0,0,0,0);

                let daysLate = 0;
                let penalty = 0.0;

                if (today > endDate) {
                    const diffTime = today.getTime() - endDate.getTime();
                    daysLate = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
                    penalty = daysLate * parseFloat(product.rental_price_per_day);
                    
                    // Cap the penalty at the deposit amount to avoid negative values
                    if (penalty > deposit) {
                        penalty = deposit;
                    }
                    
                    // Deduct from buyer's reputation score by 0.5 (clamped to 1.0)
                    const buyer = await User.findByPk(transaction.buyer_id);
                    if (buyer) {
                        buyer.reputation_score = Math.max(1.0, parseFloat(buyer.reputation_score || 5.0) - 0.5);
                        await buyer.save();
                    }

                    lateMessage = ` Late return detected by ${daysLate} days. Penalty of RM ${penalty.toFixed(2)} applied. Buyer reputation score deducted by 0.5.`;
                }

                const netRefund = deposit - penalty;
                const netRentalFee = parseFloat(transaction.amount) - deposit + penalty;

                console.log(`[Deposit Management & Late Penalties]${lateMessage} Refundable Deposit: RM ${netRefund.toFixed(2)} returned to Buyer. Rental Fee + Penalty: RM ${netRentalFee.toFixed(2)} sent to Seller.`);
            }
            
            // Calculate Carbon Savings
            let co2Saved = 0.0;
            if (product) {
                 const catName = product.categoryModel ? product.categoryModel.name : product.category;
                 const subCatName = product.subcategoryModel ? product.subcategoryModel.name : null;
                 co2Saved = getCarbonValue(catName, subCatName, product);
            }

            transaction.completed_at = new Date();
            transaction.review_status = 'PENDING_REVIEWS';
            transaction.awarded_carbon_points = co2Saved;
            
            // Calculate 2% Platform Fee based strictly on Rental Fee (amount - deposit_amount)
            const totalAmt = parseFloat(transaction.amount || 0);
            const depAmt = transaction.deposit_amount ? parseFloat(transaction.deposit_amount) : 0.0;
            const isRentItem = (product && product.type === 'Rent') || transaction.rental_start_date != null;
            const rentFee = isRentItem ? Math.max(0, totalAmt - depAmt) : totalAmt;

            const platformFee = parseFloat((rentFee * 0.02).toFixed(2));
            transaction.platform_fee = platformFee;

            // Safeguard 4: Update deposit_status to 'Refunded' ONLY IF not already 'Claimed_Forfeited' (e.g. set by Moderator)
            if (isRentItem && transaction.deposit_status !== 'Claimed_Forfeited') {
                transaction.deposit_status = 'Refunded';
            }
            await transaction.save();
            
            if (product) {
                 if (transaction.buyer_id === transaction.seller_id) {
                      // Self-trade: only increment once to prevent double-counting
                      await User.increment(
                          { items_reused: 1, total_carbon_saved: co2Saved, carbon_saved_buyer: co2Saved, carbon_saved_seller: co2Saved, accumulated_balance_due: platformFee },
                          { where: { id: transaction.buyer_id } }
                      );
                  } else {
                      // Update Buyer
                      await User.increment(
                          { items_reused: 1, total_carbon_saved: co2Saved, carbon_saved_buyer: co2Saved },
                          { where: { id: transaction.buyer_id } }
                      );
                      
                      // Update Seller (increment accumulated_balance_due by platformFee)
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
                console.error('Failed to log buy interaction:', interactionError);
            }

            // Notify Buyer that Seller completed it
            await createNotification(
                transaction.buyer_id,
                'Transaction Completed',
                `Seller has verified the completion. You can now rate your experience!`,
                'Transaction',
                transaction.id
            );
        }

        // Notify both parties of status change
        const productTitle = product ? product.title : 'Item';
        if (targetStatus === 'Scheduled') {
            await createNotification(
                otherPartyId,
                'Order Scheduled',
                `Order for "${productTitle}" has been scheduled at ${transaction.meetup_location || 'Campus Meetup Point'}.`,
                'Transaction',
                transaction.id
            );
        } else if (targetStatus === 'Cancelled') {
            if (product) {
                await Product.update(
                    { status: 'Available' },
                    { where: { id: transaction.product_id } }
                );
            }
            const isBuyerCancelling = String(requesterId) === String(transaction.buyer_id);
            const cancelTitle = isBuyerCancelling ? 'Order Cancelled by Buyer' : 'Request Declined by Seller';
            let cancelMsg = isBuyerCancelling 
                ? `Buyer has cancelled their order for "${productTitle}".` 
                : `Seller has declined your request for "${productTitle}".`;

            if (cancellation_reason && cancellation_reason.trim().length > 0) {
                cancelMsg += ` Reason: ${cancellation_reason.trim()}`;
            }

            await createNotification(
                otherPartyId,
                cancelTitle,
                cancelMsg,
                'Transaction',
                transaction.id
            );
        } else if (targetStatus === 'To Confirm') {
            await createNotification(
                otherPartyId,
                'Order Handover Ready',
                `Meetup confirmed for "${productTitle}". Please confirm completion upon handover.`,
                'Transaction',
                transaction.id
            );
        }

        // If active on rent, notify buyer
        if (targetStatus === 'On Rent') {
            await createNotification(
                transaction.buyer_id,
                'Rental Active',
                `Handover confirmed. Your rental for "${productTitle}" is now active!`,
                'Transaction',
                transaction.id
            );
        }

        if (targetStatus === 'Scheduled') {
            if (product && product.type !== 'Rent') {
                // Sale Item: Change product status to Reserved
                await Product.update(
                    { status: 'Reserved' },
                    { where: { id: transaction.product_id } }
                );

                // Auto-cancel all other pending offers for this sale item
                const otherPendingTxs = await Transaction.findAll({
                    where: {
                        product_id: transaction.product_id,
                        id: { [Op.ne]: transaction.id },
                        status: 'Pending'
                    }
                });

                for (const otherTx of otherPendingTxs) {
                    await otherTx.update({
                        status: 'Cancelled',
                        cancellation_reason: 'The seller accepted an offer from another buyer.'
                    });
                    await createNotification(
                        otherTx.buyer_id,
                        'Offer Declined',
                        `The item "${productTitle}" has been accepted by another buyer.`,
                        'Transaction',
                        otherTx.id
                    );
                    emitToUser(otherTx.buyer_id, 'transaction_status_updated', { transaction_id: otherTx.id, status: 'Cancelled' });
                }
            } else if (product && product.type === 'Rent') {
                // Rent Item: Auto-cancel pending requests that overlap with accepted rental dates
                if (transaction.rental_start_date && transaction.rental_end_date) {
                    const acceptedStart = new Date(transaction.rental_start_date);
                    const acceptedEnd = new Date(transaction.rental_end_date);

                    const overlappingPendingTxs = await Transaction.findAll({
                        where: {
                            product_id: transaction.product_id,
                            id: { [Op.ne]: transaction.id },
                            status: 'Pending',
                            rental_start_date: { [Op.lte]: acceptedEnd },
                            rental_end_date: { [Op.gte]: acceptedStart }
                        }
                    });

                    for (const otherTx of overlappingPendingTxs) {
                        await otherTx.update({
                            status: 'Cancelled',
                            cancellation_reason: 'This item was booked by another student for your selected dates.'
                        });
                        await createNotification(
                            otherTx.buyer_id,
                            'Rental Dates Unavailable',
                            `The item "${productTitle}" has been booked by another student for your selected dates.`,
                            'Transaction',
                            otherTx.id
                        );
                        emitToUser(otherTx.buyer_id, 'transaction_status_updated', { transaction_id: otherTx.id, status: 'Cancelled' });
                    }
                }
            }

            // Notify Buyer
            await createNotification(
                transaction.buyer_id,
                'Request Approved',
                `Seller has accepted your request. Please proceed to Meetup/Payment.`,
                'Transaction',
                transaction.id
            );
        }


        // UC19 Payment Proof
        if (targetStatus === 'To Confirm') {
            if (req.body.payment_proof_url) {
                transaction.payment_proof_url = req.body.payment_proof_url;
                await transaction.save();
            }
            await createNotification(
                transaction.seller_id,
                'Payment/Meetup Submitted',
                `Buyer has submitted action. Please verify and complete the order.`,
                'Transaction',
                transaction.id
            );
        }

        // If disputed, create a Dispute entry automatically
        if (targetStatus === 'Disputed') {
            // Save pre-dispute status
            transaction.pre_dispute_status = oldStatus;
            await transaction.save();

            // Check if a dispute already exists
            const existingDispute = await Dispute.findOne({ where: { transaction_id: transaction.id } });
            if (!existingDispute) {
                const dispute = await Dispute.create({
                    transaction_id: transaction.id,
                    complainant_id: requesterId || transaction.seller_id,
                    reason: 'Fraud',
                    description: `Seller reported an issue/declined payment proof during the confirmation stage.`,
                    evidence_urls: transaction.payment_proof_url ? [transaction.payment_proof_url] : [],
                    status: 'New'
                });

                // Notify Buyer
                await createNotification(
                    transaction.buyer_id,
                    'Transaction Disputed',
                    `Seller declined your payment proof. A dispute has been opened for moderation.`,
                    'Transaction',
                    dispute.id
                );

                // Notify Seller
                await createNotification(
                    transaction.seller_id,
                    'Dispute Opened',
                    `You have reported an issue with the payment proof. A dispute has been opened for moderation.`,
                    'Transaction',
                    dispute.id
                );

                // Emit new dispute event to admin room
                emitToAdmins('new_dispute_raised', dispute);
            }
        }

        // Emit status update to specific buyer and seller sockets
        emitToUser(transaction.buyer_id, 'transaction_status_updated', { 
            transaction_id: transaction.id, 
            status: transaction.status,
            cancelled_by_id: transaction.cancelled_by_id
        });
        emitToUser(transaction.seller_id, 'transaction_status_updated', { 
            transaction_id: transaction.id, 
            status: transaction.status,
            cancelled_by_id: transaction.cancelled_by_id
        });

        let successMessage = `Transaction updated to ${targetStatus}`;
        if (targetStatus === 'Completed' && product && product.type === 'Rent') {
            const endDate = new Date(transaction.rental_end_date);
            const today = new Date();
            today.setHours(0,0,0,0);
            endDate.setHours(0,0,0,0);
            if (today > endDate) {
                const diffTime = today.getTime() - endDate.getTime();
                const daysLate = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
                const penalty = Math.min(daysLate * parseFloat(product.rental_price_per_day), product.rental_deposit ? parseFloat(product.rental_deposit) : 0.0);
                successMessage = `Transaction completed. Late return penalty of RM ${penalty.toFixed(2)} applied (${daysLate} days late).`;
            }
        }

        if (targetStatus === 'Completed') {
            emitToAdmins('admin_metrics_update', { trigger: 'transaction_completed' });
        }

        res.json({ message: successMessage, transaction });
    } catch (error) {
        console.error('Update Status Error:', error);
        res.status(500).json({ error: 'Failed to update transaction' });
    }
};

export const addRating = async (req, res) => {
    try {
        const { id } = req.params;
        const { rating, review, is_seller } = req.body; // is_seller = true if rating buyer

        const transaction = await Transaction.findByPk(id);
        if (!transaction) return res.status(404).json({ error: 'Transaction not found' });

        if (is_seller) {
            transaction.rating_from_seller = rating;
            transaction.seller_comment = review;
            
            if (transaction.review_status === 'PENDING_REVIEWS') {
                transaction.review_status = 'SELLER_REVIEWED';
            } else if (transaction.review_status === 'BUYER_REVIEWED') {
                transaction.review_status = 'PUBLISHED';
            }
        } else {
            transaction.rating_from_buyer = rating;
            transaction.buyer_comment = review;

            if (transaction.review_status === 'PENDING_REVIEWS') {
                transaction.review_status = 'BUYER_REVIEWED';
            } else if (transaction.review_status === 'SELLER_REVIEWED') {
                transaction.review_status = 'PUBLISHED';
            }
        }
        await transaction.save();

        if (transaction.review_status === 'PUBLISHED') {
            // Recalculate and update reputation for both parties
            const updateReputation = async (userId) => {
                const transactions = await Transaction.findAll({
                    where: {
                        review_status: 'PUBLISHED'
                    }
                });

                let totalScore = 0;
                let count = 0;

                for (const t of transactions) {
                    if (t.seller_id === userId && t.rating_from_buyer) {
                        totalScore += t.rating_from_buyer;
                        count++;
                    } else if (t.buyer_id === userId && t.rating_from_seller) {
                        totalScore += t.rating_from_seller;
                        count++;
                    }
                }

                if (count > 0) {
                    const newScore = (totalScore / count).toFixed(2);
                    await User.update({ reputation_score: newScore, total_reviews: count }, { where: { id: userId } });
                }
            };

            await updateReputation(transaction.seller_id);
            await updateReputation(transaction.buyer_id);
        }

        res.json({ message: 'Rating submitted', review_status: transaction.review_status });
    } catch (e) {
        console.error('Rating Error', e);
        res.status(500).json({ error: 'Failed to rate' });
    }
};

export const getTransactionReceipt = async (req, res) => {
    try {
        const { id } = req.params;
        const transaction = await Transaction.findByPk(id, {
            include: [
                { model: Product, as: 'product' },
                { model: User, as: 'buyer', attributes: ['id', 'username', 'full_name', 'email'] },
                { model: User, as: 'seller', attributes: ['id', 'username', 'full_name', 'email'] }
            ]
        });

        if (!transaction) {
            return res.status(404).json({ error: 'Transaction not found' });
        }

        // Hard Backend Validation Safeguard: Receipts are ONLY available for Completed transactions
        if (transaction.status !== 'Completed') {
            return res.status(400).json({ error: 'Receipts are only available for completed transactions.' });
        }

        const reqUserId = String(req.user.id);
        if (reqUserId !== String(transaction.buyer_id) && reqUserId !== String(transaction.seller_id)) {
            return res.status(403).json({ error: 'Not authorized to view receipt for this transaction' });
        }

        res.json({
            receipt_id: `RCP-${transaction.id.substring(0, 8).toUpperCase()}`,
            transaction_id: transaction.id,
            status: transaction.status,
            issued_at: transaction.updatedAt,
            amount: transaction.amount,
            platform_fee: transaction.platform_fee,
            payment_method: transaction.selected_payment_method,
            buyer: transaction.buyer,
            seller: transaction.seller,
            product: transaction.product
        });
    } catch (error) {
        console.error('Get Receipt Error:', error);
        res.status(500).json({ error: 'Failed to generate receipt' });
    }
};

// GET /api/transactions/product/:product_id/booked-dates
export const getBookedDates = async (req, res) => {
    try {
        const { product_id } = req.params;
        const activeBookings = await Transaction.findAll({
            where: {
                product_id,
                status: ['Scheduled', 'To Confirm', 'On Rent'],
                rental_start_date: { [Op.ne]: null },
                rental_end_date: { [Op.ne]: null }
            },
            attributes: ['id', 'rental_start_date', 'rental_end_date', 'rental_type', 'status']
        });


        res.json(activeBookings);
    } catch (error) {
        console.error('Error fetching booked dates:', error);
        res.status(500).json({ error: 'Failed to fetch booked dates' });
    }
};

// POST /api/transactions/:id/return-rental (Seller/Renter confirms return & deposit refund)
export const returnRentalAndRefundDeposit = async (req, res) => {
    try {
        const { id } = req.params;
        const transaction = await Transaction.findByPk(id, { include: [{ model: Product, as: 'product' }] });
        if (!transaction) {
            return res.status(404).json({ error: 'Transaction not found' });
        }

        const reqUserId = String(req.user.id);
        if (reqUserId !== String(transaction.seller_id) && reqUserId !== String(transaction.buyer_id)) {
            return res.status(403).json({ error: 'Not authorized to process rental return' });
        }

        transaction.deposit_status = 'Refunded';
        transaction.status = 'Completed';
        transaction.completed_at = new Date();
        await transaction.save();

        // Release Product status back to Available for future rentals
        if (transaction.product) {
            transaction.product.status = 'Available';
            await transaction.product.save();
        }

        // Notify Buyer
        await createNotification(
            transaction.buyer_id,
            'Rental Returned & Deposit Refunded',
            `Your rental item "${transaction.product?.title || 'item'}" has been marked as returned cleanly. Deposit status: Refunded.`,
            'Transaction',
            transaction.id
        );

        res.json({ message: 'Rental returned successfully. Deposit marked as refunded.', transaction });
    } catch (error) {
        console.error('Error returning rental:', error);
        res.status(500).json({ error: 'Failed to process rental return' });
    }
};

// POST /api/transactions/:id/claim-deposit (Seller claims deposit due to damage)
export const claimRentalDeposit = async (req, res) => {
    try {
        const { id } = req.params;
        const { reason } = req.body;

        const transaction = await Transaction.findByPk(id, { include: [{ model: Product, as: 'product' }] });
        if (!transaction) {
            return res.status(404).json({ error: 'Transaction not found' });
        }

        if (String(req.user.id) !== String(transaction.seller_id)) {
            return res.status(403).json({ error: 'Only the item owner/seller can claim damage deposit.' });
        }

        transaction.deposit_status = 'Claimed_Forfeited';
        transaction.status = 'Disputed';
        await transaction.save();

        // Automatically file a Dispute ticket for moderation review
        const dispute = await Dispute.create({
            transaction_id: transaction.id,
            complainant_id: transaction.seller_id,
            reason: 'Rental Damage',
            description: reason || 'Seller reported damage/late return on rental item and requested deposit claim.',
            status: 'New'
        });

        // Notify Buyer
        await createNotification(
            transaction.buyer_id,
            'Deposit Claimed - Rental Dispute Opened',
            `The seller requested a deposit claim on rental item "${transaction.product?.title || 'item'}". A dispute ticket has been created for staff review.`,
            'Dispute',
            dispute.id
        );

        res.json({ message: 'Deposit claim recorded and dispute initiated for moderator review.', dispute, transaction });
    } catch (error) {
        console.error('Error claiming rental deposit:', error);
        res.status(500).json({ error: 'Failed to claim deposit' });
    }
};
