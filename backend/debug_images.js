import sequelize from './src/config/database.js';
import { Product } from './src/models/index.js';

async function run() {
    await sequelize.authenticate();
    const products = await Product.findAll();
    products.forEach(p => {
        console.log(`ID: ${p.id} | Title: ${p.title} | Image URLs: ${JSON.stringify(p.image_urls)}`);
    });
    process.exit(0);
}
run();
