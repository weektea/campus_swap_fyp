import User from './User.js';
import Product from './Product.js';
import Transaction from './Transaction.js';
import SavedItem from './SavedItem.js';
import Message from './Message.js';
import Review from './Review.js';
import Notification from './Notification.js';

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

export { User, Product, Transaction, SavedItem, Message, Review, Notification, UserInteraction };
