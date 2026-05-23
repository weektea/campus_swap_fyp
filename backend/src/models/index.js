import User from './User.js';
import Product from './Product.js';
import Transaction from './Transaction.js';
import SavedItem from './SavedItem.js';
import Message from './Message.js';
import Dispute from './Dispute.js';
import SafeMeetupZone from './SafeMeetupZone.js';
import Review from './Review.js';
import Notification from './Notification.js';
import BackupLog from './BackupLog.js';

// User <-> Product (Seller relationship)
User.hasMany(Product, { foreignKey: 'seller_id', as: 'listings' });
Product.belongsTo(User, { foreignKey: 'seller_id', as: 'seller' });

// Transaction Relationships
User.hasMany(Transaction, { foreignKey: 'buyer_id', as: 'buyer_transactions' });
User.hasMany(Transaction, { foreignKey: 'seller_id', as: 'seller_transactions' });
Transaction.belongsTo(User, { foreignKey: 'buyer_id', as: 'buyer' });
Transaction.belongsTo(User, { foreignKey: 'seller_id', as: 'seller' });

Product.hasOne(Transaction, { foreignKey: 'product_id', as: 'transaction' });
Transaction.belongsTo(Product, { foreignKey: 'product_id', as: 'product' });

// Review Relationships
Review.belongsTo(Transaction, { foreignKey: 'transaction_id', as: 'transaction' });
Transaction.hasMany(Review, { foreignKey: 'transaction_id', as: 'reviews' });

Review.belongsTo(User, { foreignKey: 'reviewer_id', as: 'reviewer' });
Review.belongsTo(User, { foreignKey: 'reviewee_id', as: 'reviewee' });
User.hasMany(Review, { foreignKey: 'reviewee_id', as: 'received_reviews' });

// Notifications
User.hasMany(Notification, { foreignKey: 'user_id', as: 'notifications' });
Notification.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

// Saved Items
User.hasMany(SavedItem, { foreignKey: 'user_id', as: 'saved_items' });
SavedItem.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

Product.hasMany(SavedItem, { foreignKey: 'product_id', as: 'saved_by_users' });
SavedItem.belongsTo(Product, { foreignKey: 'product_id', as: 'product' });

// Messages
User.hasMany(Message, { foreignKey: 'sender_id', as: 'sent_messages' });
User.hasMany(Message, { foreignKey: 'receiver_id', as: 'received_messages' });
Message.belongsTo(User, { foreignKey: 'sender_id', as: 'sender' });
Message.belongsTo(User, { foreignKey: 'receiver_id', as: 'receiver' });

import UserInteraction from './UserInteraction.js';
import Category from './Category.js';
import SubCategory from './SubCategory.js';
import Report from './Report.js';
import SupportTicket from './SupportTicket.js';

// Category Relationships
Category.hasMany(SubCategory, { foreignKey: 'category_id', as: 'subcategories' });
SubCategory.belongsTo(Category, { foreignKey: 'category_id', as: 'categoryModel' });

Category.hasMany(Product, { foreignKey: 'category_id', as: 'products' });
Product.belongsTo(Category, { foreignKey: 'category_id', as: 'categoryModel' });

SubCategory.hasMany(Product, { foreignKey: 'sub_category_id', as: 'products' });
Product.belongsTo(SubCategory, { foreignKey: 'sub_category_id', as: 'subcategoryModel' });

// Moderation: Reports
User.hasMany(Report, { foreignKey: 'reporter_id', as: 'filed_reports' });
Report.belongsTo(User, { foreignKey: 'reporter_id', as: 'reporter' });
Product.hasMany(Report, { foreignKey: 'product_id', as: 'reports' });
Report.belongsTo(Product, { foreignKey: 'product_id', as: 'product' });

// Moderation: Support Tickets
User.hasMany(SupportTicket, { foreignKey: 'user_id', as: 'support_tickets' });
SupportTicket.belongsTo(User, { foreignKey: 'user_id', as: 'student' });

// Moderation: Disputes
User.hasMany(Dispute, { foreignKey: 'complainant_id', as: 'filed_disputes' });
Dispute.belongsTo(User, { foreignKey: 'complainant_id', as: 'complainant' });
User.hasMany(Dispute, { foreignKey: 'handled_by', as: 'handled_disputes' });
Dispute.belongsTo(User, { foreignKey: 'handled_by', as: 'handler' });
Transaction.hasMany(Dispute, { foreignKey: 'transaction_id', as: 'disputes' });
Dispute.belongsTo(Transaction, { foreignKey: 'transaction_id', as: 'transaction' });

export { 
    User, Product, Transaction, SavedItem, Message, Review, 
    Notification, UserInteraction, Category, SubCategory, 
    Report, SupportTicket, Dispute, SafeMeetupZone, BackupLog
};
