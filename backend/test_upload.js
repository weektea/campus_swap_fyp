import axios from 'axios';
import fs from 'fs';
import FormData from 'form-data';

async function run() {
    const formData = new FormData();
    // Create a dummy image file
    fs.writeFileSync('dummy.jpg', 'fake image content');
    formData.append('file', fs.createReadStream('dummy.jpg'));
    
    try {
        const res = await axios.post('http://localhost:3000/api/upload', formData, {
            headers: formData.getHeaders()
        });
        console.log('Success:', res.data);
    } catch(e) {
        console.log('Error:', e.response ? e.response.data : e.message);
    }
}
run();
