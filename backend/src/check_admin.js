import sequelize from './config/database.js';
import User from './models/User.js';

async function findAdmins() {
    await sequelize.authenticate();
    const admins = await User.findAll({ where: { role: 'admin' } });
    console.log('--- ADMIN USERS ---');
    admins.forEach(a => console.log(`Email: ${a.email}, Password (Hashed): ${a.password_hash}`));
    
    if (admins.length === 0) {
        console.log('No admin users found. Creating a default admin...');
        const bcrypt = await import('bcryptjs');
        const hash = await bcrypt.default.hash('password123', 10);
        await User.create({
            email: 'admin@campus-swap.edu.my',
            password_hash: hash,
            username: 'system_admin',
            full_name: 'System Admin',
            role: 'admin',
            is_active: true
        });
        console.log('Created Default Admin:');
        console.log('Email: admin@campus-swap.edu');
        console.log('Password: password123');
    }
    
    process.exit(0);
}
findAdmins();
