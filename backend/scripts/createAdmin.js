import 'dotenv/config';
import bcrypt from 'bcryptjs';
import { User } from '../src/models/index.js';
import sequelize from '../src/config/database.js';

const createAdmin = async () => {
    try {
        await sequelize.authenticate();
        console.log('Database connected.');

        const email = process.argv[2] || 'admin@campus.edu.my';
        const password = process.argv[3] || 'Admin@123';

        // Check availability
        const existing = await User.findOne({ where: { email } });
        if (existing) {
            console.log(`User ${email} already exists. Updating role to Admin...`);
            existing.role = 'admin';
            await existing.save();
            console.log('Success! User is now an Admin.');
            process.exit(0);
        }

        // Create new
        const hashedPassword = await bcrypt.hash(password, 10);
        await User.create({
            email,
            password_hash: hashedPassword,
            username: 'super_admin',
            full_name: 'Super Admin',
            role: 'admin', // KEY PART
            phone_number: '000-0000000',
            is_verified: true,
            university_id: 'ADMIN-001'
        });

        console.log(`\n🎉 Admin User Created Successfully!`);
        console.log(`📧 Email: ${email}`);
        console.log(`🔑 Password: ${password}`);
        console.log(`\nUse these credentials to login.`);

    } catch (error) {
        console.error('Failed to create admin:', error);
    } finally {
        await sequelize.close();
    }
};

createAdmin();
