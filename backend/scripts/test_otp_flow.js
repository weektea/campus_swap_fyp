import axios from 'axios';
import { User } from '../src/models/index.js';
import sequelize from '../src/config/database.js';

const BASE_URL = 'http://localhost:3000/api';

async function testOtpFlow() {
    console.log('--- TEST: OTP Verification Flow ---');
    
    // Generate unique credentials for this test
    const suffix = Math.floor(Math.random() * 100000);
    const validEmail = `test_student_${suffix}@student.um.edu.my`;
    const invalidEmail = `test_student_${suffix}@gmail.com`;
    const username = `test_student_${suffix}`;
    const university_id = `24PMR${suffix.toString().padStart(5, '0').slice(0, 5)}`;
    const phone_number = `+6012-${suffix.toString().padStart(7, '0').slice(0, 7)}`;
    
    try {
        // Test 1: Register invalid email
        console.log('\n[Test 1] Attempting registration with invalid email:', invalidEmail);
        try {
            await axios.post(`${BASE_URL}/auth/register`, {
                email: invalidEmail,
                password: 'TestPassword@123',
                username,
                full_name: 'Test Student',
                phone_number,
                university_id
            });
            console.log('❌ Test 1 Failed: Non-edu.my registration succeeded but should have failed.');
        } catch (err) {
            if (err.response && err.response.status === 400 && err.response.data.error === 'Only valid campus emails (.edu.my) are allowed.') {
                console.log('✅ Test 1 Passed: Invalid email registration correctly blocked.');
            } else {
                console.log('❌ Test 1 Failed with unexpected response:', err.response ? err.response.data : err.message);
            }
        }

        // Test 1.5: Register with invalid full name (containing numbers or other symbols)
        console.log('\n[Test 1.5] Attempting registration with invalid full name (numbers):', 'Test Student 123');
        try {
            await axios.post(`${BASE_URL}/auth/register`, {
                email: validEmail,
                password: 'TestPassword@123',
                username,
                full_name: 'Test Student 123',
                phone_number,
                university_id
            });
            console.log('❌ Test 1.5 Failed: Invalid full name registration succeeded but should have failed.');
        } catch (err) {
            if (err.response && err.response.status === 400 && err.response.data.error === 'Full name can only contain letters, spaces, and periods.') {
                console.log('✅ Test 1.5 Passed: Invalid full name correctly blocked.');
            } else {
                console.log('❌ Test 1.5 Failed with unexpected response:', err.response ? err.response.data : err.message);
            }
        }

        // Test 2: Register valid email with valid name containing a period (e.g. "M. Test Student")
        console.log('\n[Test 2] Attempting registration with valid email and name with period:', validEmail);
        const registerRes = await axios.post(`${BASE_URL}/auth/register`, {
            email: validEmail,
            password: 'TestPassword@123',
            username,
            full_name: 'M. Test Student',
            phone_number,
            university_id
        });
        console.log('✅ Test 2 Register Request Success. Message:', registerRes.data.message);

        // Test 2.5: Attempt to login before verifying email (should fail with 403)
        console.log('\n[Test 2.5] Attempting login before verifying email...');
        try {
            await axios.post(`${BASE_URL}/auth/login`, {
                email: validEmail,
                password: 'TestPassword@123'
            });
            console.log('❌ Test 2.5 Failed: Login succeeded before verification.');
        } catch (err) {
            if (err.response && err.response.status === 403 && err.response.data.error === 'Please verify your email before logging in.') {
                console.log('✅ Test 2.5 Passed: Login correctly blocked for unverified email.');
            } else {
                console.log('❌ Test 2.5 Failed with unexpected response:', err.response ? err.response.data : err.message);
            }
        }

        // Test 3: Fetch OTP from DB and check is_email_verified is false
        console.log('\n[Test 3] Fetching user from PostgreSQL database to verify initial state...');
        const user = await User.findOne({ where: { email: validEmail } });
        if (!user) {
            throw new Error('User not found in database after successful registration.');
        }
        console.log(`Initial is_email_verified: ${user.is_email_verified}`);
        console.log(`Stored OTP: ${user.otp}, Expiry: ${user.otp_expiry}`);
        
        if (user.is_email_verified === false && user.otp) {
            console.log('✅ Test 3 Passed: User registered with is_email_verified=false and OTP saved.');
        } else {
            console.log('❌ Test 3 Failed: User status in database is incorrect.');
        }

        const otp = user.otp;

        // Test 4: Verify OTP with invalid code
        console.log('\n[Test 4] Verifying OTP with invalid code...');
        try {
            await axios.post(`${BASE_URL}/auth/verify-otp`, {
                email: validEmail,
                otp: '000000'
            });
            console.log('❌ Test 4 Failed: Verification succeeded with invalid OTP.');
        } catch (err) {
            if (err.response && err.response.status === 400) {
                console.log('✅ Test 4 Passed: Invalid OTP correctly rejected. Message:', err.response.data.error);
            } else {
                console.log('❌ Test 4 Failed with unexpected response:', err.response ? err.response.data : err.message);
            }
        }

        // Test 5: Verify OTP with correct code
        console.log('\n[Test 5] Verifying OTP with correct code:', otp);
        const verifyRes = await axios.post(`${BASE_URL}/auth/verify-otp`, {
            email: validEmail,
            otp
        });
        console.log('✅ Test 5 Verification Success. Message:', verifyRes.data.message);

        // Test 6: Verify final database status
        console.log('\n[Test 6] Fetching user again to verify final DB state...');
        const updatedUser = await User.findOne({ where: { email: validEmail } });
        console.log(`Final is_email_verified: ${updatedUser.is_email_verified}`);
        console.log(`Cleared OTP: ${updatedUser.otp}, Expiry: ${updatedUser.otp_expiry}`);
        
        if (updatedUser.is_email_verified === true && updatedUser.otp === null) {
            console.log('✅ Test 6 Passed: User email verified and OTP cleared.');
        } else {
            console.log('❌ Test 6 Failed: Final state is incorrect.');
        }

        // Clean up test user
        console.log('\nCleaning up test user...');
        await updatedUser.destroy();
        console.log('Cleanup complete.');

    } catch (err) {
        console.error('Test Execution Error:', err);
    } finally {
        await sequelize.close();
    }
}

testOtpFlow();
