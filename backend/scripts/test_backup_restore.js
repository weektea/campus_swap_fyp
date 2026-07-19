import { executeBackup } from '../src/utils/backupHelper.js';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config();

console.log('--- Database Backup Test ---');
console.log('DB Config:');
console.log('DB_HOST:', process.env.DB_HOST || 'localhost');
console.log('DB_PORT:', process.env.DB_PORT || 5432);
console.log('DB_USER:', process.env.DB_USER || 'postgres');
console.log('DB_NAME:', process.env.DB_NAME || 'campus_swap');

console.log('\nRunning executeBackup()...');
executeBackup('Manual')
    .then(log => {
        console.log('Backup successful!');
        console.log('Log record:', JSON.stringify(log, null, 2));
        process.exit(0);
    })
    .catch(err => {
        console.error('Backup failed:', err);
        process.exit(1);
    });
