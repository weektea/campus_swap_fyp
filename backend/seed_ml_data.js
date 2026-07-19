import sequelize from './src/config/database.js';
import { User, Product, UserInteraction, Category, SubCategory } from './src/models/index.js';
import bcrypt from 'bcryptjs';

async function seed() {
    try {
        console.log('Connecting to database...');
        await sequelize.authenticate();
        console.log('Connection successful.');

        console.log('Clearing old transaction, review, report, interaction, and product tables...');
        // Use TRUNCATE CASCADE to clean all dependent tables cleanly without violating foreign key constraints
        await sequelize.query('TRUNCATE TABLE "UserInteractions", "Products", "Users", "Transactions", "Reviews", "Reports", "SavedItems", "Messages", "Disputes" CASCADE;');
        console.log('Old data cleared.');

        // 1. Fetch Categories and Subcategories
        console.log('Fetching database categories and subcategories...');
        const categories = await Category.findAll({
            include: [{ model: SubCategory, as: 'subcategories' }]
        });

        const categoryMap = {};
        const subcategoryMap = {};

        categories.forEach(cat => {
            categoryMap[cat.name] = cat;
            if (cat.subcategories) {
                cat.subcategories.forEach(sub => {
                    subcategoryMap[`${cat.name}___${sub.name}`] = sub;
                });
            }
        });

        // Helper to get category/subcategory models
        const getCatInfo = (catName, subcatName) => {
            const cat = categoryMap[catName];
            const sub = subcategoryMap[`${catName}___${subcatName}`];
            return {
                category_id: cat ? cat.id : null,
                sub_category_id: sub ? sub.id : null,
                category: catName
            };
        };

        // 2. Create Mock Users
        console.log('Creating dummy student and admin users...');
        const usersData = [];

        // Dynamically hash passwords using bcrypt
        const studentPasswordHash = await bcrypt.hash('password123', 10);
        const testStudentPasswordHash = await bcrypt.hash('TestPassword@123', 10);
        const adminPasswordHash = await bcrypt.hash('Admin@123', 10);

        // Add standard super admin
        usersData.push({
            email: 'admin@campus.edu.my',
            username: 'super_admin',
            full_name: 'Super Admin',
            password_hash: adminPasswordHash,
            role: 'admin',
            phone_number: '000-0000000',
            is_verified: true,
            university_id: 'ADMIN-001',
            status: 'active'
        });

        // Add standard test student
        usersData.push({
            email: 'test_student_01@student.um.edu.my',
            username: 'test_student_one',
            full_name: 'Test Student One',
            password_hash: testStudentPasswordHash,
            role: 'student',
            phone_number: '+6012-3456789',
            is_verified: true,
            is_email_verified: true,
            university_id: '24PMR12345',
            status: 'active'
        });

        // Persona A: Tech Geeks
        const techUsernames = ['tech_alice', 'gadget_bob', 'silicon_charlie', 'byte_david', 'circuit_eve', 'vector_frank', 'pixel_grace'];
        techUsernames.forEach((username, i) => {
            usersData.push({
                email: `${username}@student.edu.my`,
                username,
                full_name: username.replace('_', ' ').replace(/\b\w/g, c => c.toUpperCase()),
                password_hash: studentPasswordHash,
                role: 'student',
                university_id: `24TEC${String(i + 1).padStart(5, '0')}`, // e.g., 24TEC00001
                is_verified: true,
                is_email_verified: true,
                reputation_score: 4.5 + Math.random() * 0.5,
                bio: `Tech enthusiast. Love tinkering with hardware. Persona A (i=${i}).`,
                year_of_study: 2,
                status: 'active'
            });
        });

        // Persona B: Study Hard
        const studyUsernames = ['study_ivy', 'nerd_jack', 'library_karen', 'bookworm_leo', 'pencil_mia', 'exam_noah', 'thesis_olivia'];
        studyUsernames.forEach((username, i) => {
            usersData.push({
                email: `${username}@student.edu.my`,
                username,
                full_name: username.replace('_', ' ').replace(/\b\w/g, c => c.toUpperCase()),
                password_hash: studentPasswordHash,
                role: 'student',
                university_id: `24STD${String(i + 1).padStart(5, '0')}`, // e.g., 24STD00001
                is_verified: true,
                is_email_verified: true,
                reputation_score: 4.8 + Math.random() * 0.2,
                bio: `Dean's lister. Bookworm. Focus on exams. Persona B (i=${i}).`,
                year_of_study: 3,
                status: 'active'
            });
        });

        // Persona C: Active Lifestyle
        const activeUsernames = ['runner_paul', 'sneaker_quinn', 'badminton_ryan', 'sporty_sam', 'cycle_tina', 'active_uma'];
        activeUsernames.forEach((username, i) => {
            usersData.push({
                email: `${username}@student.edu.my`,
                username,
                full_name: username.replace('_', ' ').replace(/\b\w/g, c => c.toUpperCase()),
                password_hash: studentPasswordHash,
                role: 'student',
                university_id: `24ACT${String(i + 1).padStart(5, '0')}`, // e.g., 24ACT00001
                is_verified: true,
                is_email_verified: true,
                reputation_score: 4.2 + Math.random() * 0.8,
                bio: `Active lifestyle. Outdoor workouts. Persona C (i=${i}).`,
                year_of_study: 1,
                status: 'active'
            });
        });

        const users = await User.bulkCreate(usersData, { returning: true });
        console.log(`Successfully created ${users.length} dummy users.`);

        // 3. Create Mock Products (at least 60 items)
        console.log('Creating dummy products...');
        const productsData = [];

        const items = [
            // --- Category: Electronics & Gadgets ---
            { title: 'iPad Pro 11-inch (M1)', desc: 'Used for one year, perfect for GoodNotes. Comes with Apple Pencil 2.', price: 2499.00, cat: 'Electronics & Gadgets', subcat: 'Tablets' },
            { title: 'Samsung Galaxy Tab S7 FE', desc: '12.4 inch screen, perfect for attending lectures and multitasking.', price: 1599.00, cat: 'Electronics & Gadgets', subcat: 'Tablets' },
            { title: 'iPad Air 4th Gen', desc: 'Green color, 64GB. Great companion for online lectures and drawing.', price: 1799.00, cat: 'Electronics & Gadgets', subcat: 'Tablets' },
            { title: 'Huawei MatePad 11', desc: 'Includes smart keyboard and M-Pencil. Lightweight student tablet.', price: 1199.00, cat: 'Electronics & Gadgets', subcat: 'Tablets' },
            { title: 'iPad Mini 6', desc: 'Super portable tablet. Easily fits in pocket/bag for on-the-go studies.', price: 1899.00, cat: 'Electronics & Gadgets', subcat: 'Tablets' },
            { title: 'MacBook Air M1 (2020)', desc: '8GB RAM, 256GB SSD. Battery health 90%. Best laptop for university.', price: 2399.00, cat: 'Electronics & Gadgets', subcat: 'Laptops' },
            { title: 'ThinkPad X280', desc: 'Core i5, 8GB RAM. Sturdy and reliable coding machine for CS students.', price: 850.00, cat: 'Electronics & Gadgets', subcat: 'Laptops' },
            { title: 'Dell Vostro 14', desc: 'Perfect budget student laptop for word processing and web browsing.', price: 1100.00, cat: 'Electronics & Gadgets', subcat: 'Laptops' },
            { title: 'Sony WH-1000XM4', desc: 'Noise cancelling headphones, essential for studying in noisy cafeterias.', price: 699.00, cat: 'Electronics & Gadgets', subcat: 'Audio' },
            { title: 'AirPods 2nd Gen', desc: 'Compact wireless earbuds, works perfectly for online classes.', price: 299.00, cat: 'Electronics & Gadgets', subcat: 'Audio' },
            { title: 'Logitech MX Master 3', desc: 'Ergonomic wireless mouse, super comfortable for long thesis writing.', price: 280.00, cat: 'Electronics & Gadgets', subcat: 'PC Accessories' },
            { title: 'Keychron K2 Mechanical Keyboard', desc: 'Wireless mechanical keyboard with tactile brown switches.', price: 250.00, cat: 'Electronics & Gadgets', subcat: 'PC Accessories' },
            { title: 'Kindle Paperwhite 11th Gen', desc: '6.8 inch display. Great for reading textbooks and novels.', price: 499.00, cat: 'Electronics & Gadgets', subcat: 'Tablets' },
            { title: 'Logitech C920 HD Webcam', desc: 'Perfect for online presentations and zoom calls.', price: 220.00, cat: 'Electronics & Gadgets', subcat: 'PC Accessories' },
            { title: 'Anker Power Bank 20,000mAh', desc: 'High capacity power bank to charge laptop and phone during classes.', price: 120.00, cat: 'Electronics & Gadgets', subcat: 'Others' },

            // --- Category: Books & Study Materials ---
            { title: 'Casio fx-570EX ClassWiz', desc: 'Scientific calculator, highly recommended for engineering and mathematics.', price: 85.00, cat: 'Books & Study Materials', subcat: 'Calculators' },
            { title: 'Casio fx-991EX ClassWiz', desc: 'Advanced scientific calculator. Solar powered. Clean condition.', price: 95.00, cat: 'Books & Study Materials', subcat: 'Calculators' },
            { title: 'Texas Instruments TI-84 Plus CE', desc: 'Graphing calculator, perfect for statistics and calculus courses.', price: 499.00, cat: 'Books & Study Materials', subcat: 'Calculators' },
            { title: 'CS101 Intro to Programming Notes', desc: 'Comes with past year exam answers and cheat sheets.', price: 15.00, cat: 'Books & Study Materials', subcat: 'Notes & Past Papers' },
            { title: 'Calculus I Handwritten Study Guide', desc: 'Color-coded comprehensive notes covering all formulas.', price: 20.00, cat: 'Books & Study Materials', subcat: 'Notes & Past Papers' },
            { title: 'Engineering Mechanics Past Papers', desc: 'Compilation of past exam papers with detailed step-by-step solutions.', price: 25.00, cat: 'Books & Study Materials', subcat: 'Notes & Past Papers' },
            { title: 'Macroeconomics Cheat Sheets', desc: 'Important charts and summary sheets for midterms and finals.', price: 10.00, cat: 'Books & Study Materials', subcat: 'Notes & Past Papers' },
            { title: 'Organic Chemistry Study Pack', desc: 'Full set of handwritten reaction mechanism notes.', price: 30.00, cat: 'Books & Study Materials', subcat: 'Notes & Past Papers' },
            { title: 'Calculus II Study Guide', desc: 'Senior\'s study guide covering integration techniques.', price: 18.00, cat: 'Books & Study Materials', subcat: 'Notes & Past Papers' },
            { title: 'Statistics Formula Sheets', desc: 'Comprehensive formula reference sheets.', price: 8.00, cat: 'Books & Study Materials', subcat: 'Notes & Past Papers' },
            { title: 'Financial Accounting 101 Notes', desc: 'Full semester notes with example double-entry templates.', price: 22.00, cat: 'Books & Study Materials', subcat: 'Notes & Past Papers' },
            { title: 'Introduction to Algorithms (CLRS)', desc: 'Hardcover textbook, 3rd edition. Essential for algorithm design.', price: 150.00, cat: 'Books & Study Materials', subcat: 'Books' },
            { title: 'University Physics 14th Edition', desc: 'Huge textbook covering mechanics and thermodynamics.', price: 120.00, cat: 'Books & Study Materials', subcat: 'Books' },
            { title: 'Lab Report Templates & Guidelines', desc: 'Printed guidelines for writing standard engineering lab reports.', price: 5.00, cat: 'Books & Study Materials', subcat: 'Others' },

            // --- Category: Fashion & Accessories ---
            { title: 'Formal Blazer for Presentation', desc: 'Black formal suit jacket, unisex. Worn once for FYP presentation.', price: 79.00, cat: 'Fashion & Accessories', subcat: 'Clothing' },
            { title: 'University Varsity Jacket', desc: 'Navy blue campus varsity jacket, comfortable and warm.', price: 85.00, cat: 'Fashion & Accessories', subcat: 'Clothing' },
            { title: 'White Collar Presentation Shirt', desc: 'Unisex plain white button-down formal shirt.', price: 35.00, cat: 'Fashion & Accessories', subcat: 'Clothing' },
            { title: 'Nike Air Force 1', desc: 'All white sneakers, classic style. Size EU 42. Clean.', price: 199.00, cat: 'Fashion & Accessories', subcat: 'Shoes' },
            { title: 'Adidas Stan Smith', desc: 'Comfortable casual campus sneakers. Size EU 40.', price: 150.00, cat: 'Fashion & Accessories', subcat: 'Shoes' },
            { title: 'Herschel Heritage Backpack', desc: 'Classic backpack with laptop sleeve. Sturdy school bag.', price: 120.00, cat: 'Fashion & Accessories', subcat: 'Bags & Luggage' },
            { title: 'Kanken Classic Backpack', desc: 'Waterproof fabric, yellow color. Cute daily backpack.', price: 140.00, cat: 'Fashion & Accessories', subcat: 'Bags & Luggage' },
            { title: 'Casio Vintage Digital Watch', desc: 'Silver vintage-style metal strap digital watch.', price: 99.00, cat: 'Fashion & Accessories', subcat: 'Fashion Accessories' },

            // --- Category: Furniture & Appliances ---
            { title: 'Ergonomic Office Chair', desc: 'Mesh back office chair with adjustable lumbar support.', price: 180.00, cat: 'Furniture & Appliances', subcat: 'Chairs' },
            { title: 'Plastic Study Chair', desc: 'Simple red plastic chair for study desks.', price: 15.00, cat: 'Furniture & Appliances', subcat: 'Chairs' },
            { title: 'IKEA LINNMON Study Table', desc: 'White desk with black legs. 100x60cm, fits in small dorm rooms.', price: 65.00, cat: 'Furniture & Appliances', subcat: 'Tables & Desks' },
            { title: 'Plastic Drawer Organizer', desc: '3-tier storage drawers for organizing documents and snacks.', price: 25.00, cat: 'Furniture & Appliances', subcat: 'Storage' },
            { title: 'Mini Desktop Fan', desc: 'USB-powered cooling fan, essential for hot dorm rooms.', price: 19.00, cat: 'Furniture & Appliances', subcat: 'Appliances' },
            { title: 'Electric Kettle 1.5L', desc: 'Boils water in 3 minutes. Perfect for instant noodles.', price: 35.00, cat: 'Furniture & Appliances', subcat: 'Appliances' },
            { title: 'LED Desk Lamp', desc: 'Eye-care reading lamp with 3 brightness modes and USB charger.', price: 29.00, cat: 'Furniture & Appliances', subcat: 'Others' },

            // --- Category: Sports ---
            { title: 'Decathlon Rockrider Mountain Bike', desc: 'Great for riding around campus. Front suspension.', price: 450.00, cat: 'Sports', subcat: 'Bicycles' },
            { title: 'Yonex Nanoray Badminton Racket', desc: 'Lightweight graphite racket, pre-strung.', price: 89.00, cat: 'Sports', subcat: 'Equipment' },
            { title: 'Spalding TF-150 Basketball', desc: 'Size 7 outdoor basketball. Good grip.', price: 75.00, cat: 'Sports', subcat: 'Equipment' },
            { title: 'Running Shorts with Pockets', desc: 'Quick-dry athletic shorts.', price: 20.00, cat: 'Sports', subcat: 'Apparel' },
            { title: 'Yoga Mat 6mm', desc: 'Non-slip yoga and fitness mat, comes with carrying strap.', price: 35.00, cat: 'Sports', subcat: 'Others' },

            // --- Category: Stationery ---
            { title: 'MUJI Gel Ink Pens (Pack of 5)', desc: '0.5mm black ink pens, writing smoothly.', price: 15.00, cat: 'Stationery', subcat: 'Writing' },
            { title: 'Pilot Metropolitan Fountain Pen', desc: 'Classic black metal body, fine nib.', price: 75.00, cat: 'Stationery', subcat: 'Writing' },
            { title: 'Faber-Castell Watercolor Pencils', desc: '24 colors, includes watercolor brush.', price: 35.00, cat: 'Stationery', subcat: 'Art Supplies' },
            { title: 'A4 Double A Copier Paper', desc: '80gsm, 500 sheets. Brand new pack.', price: 14.00, cat: 'Stationery', subcat: 'Paper' },
            { title: 'Mildliner Highlighters (Double-ended)', desc: 'Pack of 5 pastel colors, great for highlighting notes.', price: 18.00, cat: 'Stationery', subcat: 'Others' },
            { title: 'MUJI Notebook Set (Pack of 5)', desc: 'A5 ruled notebooks, minimal design.', price: 12.00, cat: 'Stationery', subcat: 'Others' },

            // --- Category: Vehicle ---
            { title: 'Perodua Myvi 1.3 (2015)', desc: 'Automatic, gold color. Fuel efficient student car.', price: 18500.00, cat: 'Vehicle', subcat: 'Car' },

            // --- Category: Others ---
            { title: 'Innisfree No Sebum Powder', desc: 'Controls facial oil, brand new in box.', price: 25.00, cat: 'Others', subcat: 'Cosmetics & Beauty' },
            { title: 'Hydro Flask 32oz Wide Mouth', desc: 'Insulated stainless steel water bottle. Keeps water cold all day.', price: 149.00, cat: 'Others', subcat: 'Drinkware' },
            { title: 'Thermos Mug 500ml', desc: 'Keep coffee hot during early morning classes.', price: 89.00, cat: 'Others', subcat: 'Drinkware' },
            { title: 'IKEA Frakta Blue Shopping Bag', desc: 'Extra large durable bag, extremely useful for moving out.', price: 6.00, cat: 'Others', subcat: 'Miscellaneous' }
        ];

        items.forEach((item, index) => {
            // Assign seller cyclically among dummy users
            const seller = users[index % users.length];
            const catInfo = getCatInfo(item.cat, item.subcat);
            
            // Image placeholders
            const imgNum = 100 + index;
            const image_urls = [
                `https://picsum.photos/id/${imgNum}/600/400`,
                `https://picsum.photos/id/${imgNum + 100}/600/400`
            ];

            productsData.push({
                title: item.title,
                description: item.desc,
                price: item.price,
                ...catInfo,
                condition: ['New', 'Like New', 'Good', 'Fair'][index % 4],
                image_urls,
                status: 'Available',
                seller_id: seller.id,
                type: 'Sale'
            });
        });

        const products = await Product.bulkCreate(productsData, { returning: true });
        console.log(`Successfully created ${products.length} dummy products.`);

        // 4. Generate User Interactions (Views, Saves, Messages, Buys)
        console.log('Generating persona-based user interaction matrix...');
        const interactions = [];

        // Tech Geeks index: 0-6
        // Study Hard index: 7-13
        // Active Lifestyle index: 14-19

        const getInteractionType = () => {
            const rand = Math.random();
            if (rand < 0.60) return { type: 'view', weight: 1 };
            if (rand < 0.80) return { type: 'save', weight: 5 };
            if (rand < 0.95) return { type: 'message', weight: 3 };
            return { type: 'buy', weight: 10 };
        };

        users.forEach((user) => {
            // Skip admin users from getting mock interactions
            if (user.role === 'admin') return;

            // Identify persona and select target products
            let targetProducts = [];
            let noiseProducts = [];

            // Determine persona based on username
            const username = user.username;
            const isTechGeek = techUsernames.includes(username) || username === 'test_student_one';
            const isStudyHard = studyUsernames.includes(username);
            const isActiveLife = activeUsernames.includes(username);

            products.forEach(p => {
                // Cannot interact with own listing
                if (p.seller_id === user.id) return;

                const isTech = p.category === 'Electronics & Gadgets';
                const isStudy = p.category === 'Books & Study Materials' || p.category === 'Stationery';
                const isSporty = p.category === 'Sports' || p.category === 'Fashion & Accessories';

                if (isTechGeek) {
                    // Persona A: Tech Geek
                    if (isTech) targetProducts.push(p);
                    else noiseProducts.push(p);
                } else if (isStudyHard) {
                    // Persona B: Study Hard
                    if (isStudy) targetProducts.push(p);
                    else noiseProducts.push(p);
                } else if (isActiveLife) {
                    // Persona C: Active Lifestyle
                    if (isSporty) targetProducts.push(p);
                    else noiseProducts.push(p);
                } else {
                    // General fallback
                    if (isTech || isStudy || isSporty) targetProducts.push(p);
                    else noiseProducts.push(p);
                }
            });

            // Add target interactions
            const numTargets = 15 + Math.floor(Math.random() * 10); // 15-25 interactions
            for (let t = 0; t < numTargets; t++) {
                if (targetProducts.length === 0) break;
                const p = targetProducts[Math.floor(Math.random() * targetProducts.length)];
                const interaction = getInteractionType();
                
                interactions.push({
                    user_id: user.id,
                    product_id: p.id,
                    interaction_type: interaction.type,
                    weight: interaction.weight
                });
            }

            // Add noise interactions for realism (low density)
            const numNoise = 2 + Math.floor(Math.random() * 4); // 2-5 noise interactions
            for (let n = 0; n < numNoise; n++) {
                if (noiseProducts.length === 0) break;
                const p = noiseProducts[Math.floor(Math.random() * noiseProducts.length)];
                const interaction = getInteractionType();
                
                interactions.push({
                    user_id: user.id,
                    product_id: p.id,
                    interaction_type: interaction.type,
                    weight: interaction.weight
                });
            }
        });

        const createdInteractions = await UserInteraction.bulkCreate(interactions);
        console.log(`Successfully generated ${createdInteractions.length} interaction records.`);

        console.log('Database seeding completed successfully for ML testing!');
        process.exit(0);
    } catch (e) {
        console.error('Seeding failed with error:', e);
        process.exit(1);
    }
}

seed();
