import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import pg from 'pg';
import axios from 'axios';

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;
const ML_SERVICE_URL = process.env.ML_SERVICE_URL || 'http://localhost:8000';

app.use(cors());
app.use(express.json());

// Database Connection
// Database Connection
import sequelize from './config/database.js';
import { User, Product, Transaction } from './models/index.js';

// Test DB Connection & Sync
if (process.env.NODE_ENV !== 'test') {
    sequelize.authenticate()
        .then(() => {
            console.log('Connected to PostgreSQL');
            // Sync models to database (create tables if not exist)
            // Note: In production, use migrations instead of { alter: true }
            return sequelize.sync({ alter: true });
        })
        .then(() => console.log('Database synced'))
        .catch(err => console.error('Connection error', err));
}

// Routes
import authRoutes from './routes/authRoutes.js';
import productRoutes from './routes/productRoutes.js';
import transactionRoutes from './routes/transactionRoutes.js';
import savedRoutes from './routes/savedRoutes.js';
import messageRoutes from './routes/messageRoutes.js';
import reviewRoutes from './routes/reviewRoutes.js';
import notificationRoutes from './routes/notificationRoutes.js';
import uploadRoutes from './routes/uploadRoutes.js';
import recommendationRoutes from './routes/recommendationRoutes.js';



app.use('/api/auth', authRoutes);
app.use('/api/products', productRoutes);
app.use('/api/transactions', transactionRoutes);
app.use('/api/saved', savedRoutes);
app.use('/api/messages', messageRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/recommendations', recommendationRoutes);


import adminRoutes from './routes/adminRoutes.js';
app.use('/api/admin', adminRoutes);

app.use('/admin', express.static('src/public/admin')); // Serve Admin UI
app.use('/web', express.static('src/public/web')); // Serve Student Web UI
app.use('/uploads', express.static('uploads')); // Serve Images

app.get('/', (req, res) => {
    res.json({ message: 'Welcome to Campus Swap API' });
});

app.get('/api/health', (req, res) => {
    res.json({ status: 'OK', timestamp: new Date() });
});

// File Upload Setup
import multer from 'multer';
import FormData from 'form-data';
import fs from 'fs';

const upload = multer({ dest: 'uploads/' });

app.post('/api/products/classify', upload.single('file'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No file uploaded' });
        }

        const formData = new FormData();
        formData.append('file', fs.createReadStream(req.file.path));

        console.log('Forwarding image to ML Service...');
        const response = await axios.post(`${ML_SERVICE_URL}/classify-image`, formData, {
            headers: {
                ...formData.getHeaders(),
            },
        });

        // Valid response from ML
        res.json(response.data);

        // Cleanup: delete temp file
        fs.unlinkSync(req.file.path);
    } catch (error) {
        console.error('ML Service Error:', error.message);
        // Cleanup if file exists
        if (req.file && fs.existsSync(req.file.path)) {
            fs.unlinkSync(req.file.path);
        }

        // Fallback Mock (if ML is down)
        res.json({
            category: 'Electronics (Mock Fallback)',
            confidence: 0.95,
            note: 'ML Service unavailable, using mock.'
        });
    }
});

app.post('/api/products/recommend', async (req, res) => {
    try {
        const response = await axios.post(`${ML_SERVICE_URL}/recommend`, req.body);
        res.json(response.data);
    } catch (error) {
        console.error('ML Service Error:', error.message);
        res.json({
            product_ids: ['mock_1', 'mock_2'],
            confidence: 0.8,
            note: 'ML Service unavailable, using mock.'
        });
    }
});

app.post('/api/products/price-suggestion', async (req, res) => {
    try {
        const response = await axios.post(`${ML_SERVICE_URL}/predict-price`, req.body);
        res.json(response.data);
    } catch (error) {
        console.error('ML Service Error:', error.message);
        // Fallback
        res.json({ estimated_price: 45.00, currency: 'RM', note: 'Mock Fallback' });
    }
});

app.post('/api/products/generate-description', async (req, res) => {
    try {
        const response = await axios.post(`${ML_SERVICE_URL}/generate-description`, req.body);
        res.json(response.data);
    } catch (error) {
        console.error('ML Service Error:', error.message);
        res.json({ description: 'Great condition, must have! (Fallback)' });
    }
});

// Start Server
// Start Server
app.listen(port, '0.0.0.0', () => {
    console.log(`Server running on port ${port}`);
});
