import { Product } from './src/models/index.js';

async function checkProducts() {
    try {
        const products = await Product.findAll();
        console.log('Total Products:', products.length);
        products.forEach(p => {
            console.log(`ID: ${p.id} | Title: ${p.title} | Price: ${p.price} | Status: ${p.status} | Type: ${p.type}`);
        });
    } catch (error) {
        console.error('Error fetching products:', error);
    }
}

checkProducts();
