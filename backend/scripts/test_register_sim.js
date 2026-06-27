
import axios from 'axios';

const BASE_URL = 'http://localhost:3000/api';

async function testRegister() {
    console.log('--- TEST: Register Simulation ---');
    try {
        const payload = {
            email: 'test_student_01@student.um.edu.my',
            password: 'TestPassword@123',
            username: 'test_student_one',
            full_name: 'Test Student One',
            phone_number: '+6012-3456789',
            university_id: '24PMR12345'
        };

        console.log('Sending payload:', payload);

        const response = await axios.post(`${BASE_URL}/auth/register`, payload);
        console.log('✅ Register SUCCESS!');
        console.log('Status:', response.status);
        console.log('Data:', response.data);
    } catch (error) {
        console.log('❌ Register FAILED');
        if (error.response) {
            console.log('Status:', error.response.status);
            console.log('Error Data:', error.response.data);
        } else {
            console.log('Error Message:', error.message);
        }
    }
}

testRegister();
