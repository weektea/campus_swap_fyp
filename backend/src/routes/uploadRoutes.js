import express from 'express';
import multer from 'multer';
import path from 'path';
import fs from 'fs';
import { authenticateTokenOptional } from '../middleware/authMiddleware.js';

const router = express.Router();

// Configure Storage
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        const uploadDir = 'uploads/';
        if (!fs.existsSync(uploadDir)) {
            fs.mkdirSync(uploadDir, { recursive: true });
        }
        cb(null, uploadDir);
    },
    filename: (req, file, cb) => {
        // Create unique string: timestamp-random-original_ext
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        const ext = path.extname(file.originalname).toLowerCase() || '.jpg';
        const isDoc = /pdf|doc|docx|xls|xlsx|txt|zip/.test(ext);
        const prefix = isDoc ? 'file-' : 'image-';
        cb(null, prefix + uniqueSuffix + ext);
    }
});

const upload = multer({
    storage: storage,
    limits: { fileSize: 50 * 1024 * 1024 }, // 50MB limit to support documents & videos
    fileFilter: (req, file, cb) => {
        const allowedTypes = /jpeg|jpg|png|gif|webp|mp4|webm|mov|pdf|doc|docx|xls|xlsx|txt|zip/;
        const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
        const mimetype = allowedTypes.test(file.mimetype) || 
                         file.mimetype === 'application/octet-stream' ||
                         file.mimetype === 'application/pdf' ||
                         file.mimetype.includes('document') ||
                         file.mimetype.includes('sheet') ||
                         file.mimetype.includes('text');

        if (extname || mimetype) {
            return cb(null, true);
        } else {
            cb(new Error('File type not supported. Allowed formats: images (jpeg, png, webp), videos (mp4), documents (pdf, doc, docx, txt, zip).'));
        }
    }
});

// Helper middleware for Multer error handling
const handleMulterUpload = (req, res, next) => {
    upload.single('file')(req, res, (err) => {
        if (err instanceof multer.MulterError) {
            return res.status(400).json({ error: `Upload error: ${err.message}` });
        } else if (err) {
            return res.status(400).json({ error: err.message });
        }
        next();
    });
};

// Route: POST /api/upload
router.post('/', authenticateTokenOptional, handleMulterUpload, (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No file uploaded' });
        }

        // Return the full URL relative to server root
        const fileUrl = `/uploads/${req.file.filename}`;

        res.json({
            message: 'File uploaded successfully',
            url: fileUrl,
            originalname: req.file.originalname,
            filename: req.file.filename,
            mimetype: req.file.mimetype,
            size: req.file.size
        });
    } catch (error) {
        console.error('Upload Error:', error);
        res.status(500).json({ error: 'Failed to upload file' });
    }
});

export default router;
