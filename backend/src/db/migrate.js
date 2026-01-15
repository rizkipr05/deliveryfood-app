require("dotenv").config();
const { openDb, run, get, all } = require("./sqlite");
const bcrypt = require("bcryptjs");

(async () => {
  const db = openDb();

  try {
        await run(
      db,
      `
      CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        store TEXT NOT NULL,
        price INTEGER NOT NULL,
        rating REAL NOT NULL DEFAULT 4.9,
        image TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      );
      `
    );

    await run(db, `CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);`);

    const columns = await all(db, `PRAGMA table_info(products)`);
    const hasCol = (name) => columns.some((c) => c.name === name);
    if (!hasCol("is_promo")) {
      await run(db, `ALTER TABLE products ADD COLUMN is_promo INTEGER NOT NULL DEFAULT 0`);
    }
    if (!hasCol("promo_price")) {
      await run(db, `ALTER TABLE products ADD COLUMN promo_price INTEGER`);
    }
    if (!hasCol("discount_percent")) {
      await run(db, `ALTER TABLE products ADD COLUMN discount_percent INTEGER`);
    }

    await run(
      db,
      `
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'customer',
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      );
      `
    );

    const userColumns = await all(db, `PRAGMA table_info(users)`);
    const hasUserCol = (name) => userColumns.some((c) => c.name === name);
    if (!hasUserCol("phone")) {
      await run(db, `ALTER TABLE users ADD COLUMN phone TEXT`);
    }
    if (!hasUserCol("avatar_url")) {
      await run(db, `ALTER TABLE users ADD COLUMN avatar_url TEXT`);
    }

    await run(
      db,
      `
      CREATE TABLE IF NOT EXISTS addresses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        detail TEXT NOT NULL,
        is_primary INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
      );
      `
    );

    await run(
      db,
      `
      CREATE TABLE IF NOT EXISTS cart_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        qty INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now')),
        UNIQUE(user_id, product_id),
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE
      );
      `
    );

    await run(
      db,
      `
      CREATE TABLE IF NOT EXISTS ulasan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        star INTEGER NOT NULL,
        comment TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE
      );
      `
    );

    await run(
      db,
      `
      CREATE TABLE IF NOT EXISTS orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        payment_method TEXT NOT NULL,
        payment_status TEXT NOT NULL DEFAULT 'pending',
        payment_token TEXT,
        payment_url TEXT,
        payment_qr TEXT,
        bank_code TEXT,
        va_number TEXT,
        va_expired_at TEXT,
        biller_code TEXT,
        bill_key TEXT,
        delivery_method TEXT NOT NULL,
        address TEXT,
        note TEXT,
        subtotal INTEGER NOT NULL,
        delivery_fee INTEGER NOT NULL DEFAULT 0,
        total INTEGER NOT NULL,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
      );
      `
    );

    const orderColumns = await all(db, `PRAGMA table_info(orders)`);
    const hasOrderCol = (name) => orderColumns.some((c) => c.name === name);
    if (!hasOrderCol("payment_qr")) {
      await run(db, `ALTER TABLE orders ADD COLUMN payment_qr TEXT`);
    }
    if (!hasOrderCol("midtrans_order_id")) {
      await run(db, `ALTER TABLE orders ADD COLUMN midtrans_order_id TEXT`);
    }
    if (!hasOrderCol("bank_code")) {
      await run(db, `ALTER TABLE orders ADD COLUMN bank_code TEXT`);
    }
    if (!hasOrderCol("va_number")) {
      await run(db, `ALTER TABLE orders ADD COLUMN va_number TEXT`);
    }
    if (!hasOrderCol("va_expired_at")) {
      await run(db, `ALTER TABLE orders ADD COLUMN va_expired_at TEXT`);
    }
    if (!hasOrderCol("biller_code")) {
      await run(db, `ALTER TABLE orders ADD COLUMN biller_code TEXT`);
    }
    if (!hasOrderCol("bill_key")) {
      await run(db, `ALTER TABLE orders ADD COLUMN bill_key TEXT`);
    }

    await run(
      db,
      `
      CREATE TABLE IF NOT EXISTS order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        qty INTEGER NOT NULL,
        price INTEGER NOT NULL,
        promo_price INTEGER,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY(order_id) REFERENCES orders(id) ON DELETE CASCADE,
        FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE
      );
      `
    );

    // Seed products jika masih kosong
    const pCount = await get(db, `SELECT COUNT(*) as c FROM products`);
    if ((pCount?.c ?? 0) === 0) {
      const seed = [
        ["Burger Spesial", "Makanan", "Warung Pak Tri", 25000, 4.9, "burger.png"],
        ["Nasi Pecel", "Makanan", "Warung Pak Komto", 25000, 4.9, "nasipecel.png"],
        ["Nasi Goreng Spesial", "Makanan", "Warung Pak Komto", 25000, 4.9, "nasigoreng.png"],
        ["Es Teh", "Minuman", "Warung Pak Tri", 5000, 4.9, "esteh.png"],
        ["Es Jeruk", "Minuman", "Warung Pak Komto", 25000, 4.9, "esjeruk.png"],
        ["Tempe Mendoan", "Snacks", "Warung Pak Tri", 25000, 4.9, "tempe.png"],
        ["Cilok", "Snacks", "Warung Bu Sri", 25000, 4.9, "cilok.png"],
        ["Pisang Keju", "Dessert", "Warung Pak Tri", 25000, 4.9, "pisangkeju.png"],
        ["Salad Buah", "Dessert", "Warung Bu Sri", 25000, 4.9, "salahbuah.png"],
        ["French Fries", "Snacks", "WOW", 25000, 4.9, "kentang.png"],
        ["Roti Bakar", "Dessert", "Warung Pak Madjid", 25000, 4.9, "rotibakar.png"],
      ];

      for (const finalRow of seed) {
        await run(
          db,
          `INSERT INTO products (name, category, store, price, rating, image) VALUES (?,?,?,?,?,?)`,
          finalRow
        );
      }
      console.log("✅ Seed products inserted");
    }

    // mark some promos
    await run(
      db,
      `
      UPDATE products
      SET is_promo = 1,
          promo_price = CASE
            WHEN price >= 25000 THEN price - 10000
            WHEN price >= 15000 THEN price - 5000
            ELSE price - 2000
          END,
          discount_percent = CASE
            WHEN price > 0 THEN ROUND(((price - (CASE
              WHEN price >= 25000 THEN price - 10000
              WHEN price >= 15000 THEN price - 5000
              ELSE price - 2000
            END)) * 100.0) / price)
            ELSE 0
          END
      WHERE id IN (1, 3, 5, 8, 10)
      `
    );

    await run(
      db,
      `
      CREATE TABLE IF NOT EXISTS promos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        subtitle TEXT NOT NULL,
        color TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      );
      `
    );

    const promoCount = await get(db, `SELECT COUNT(*) as c FROM promos`);
    if ((promoCount?.c ?? 0) === 0) {
      const promos = [
        ["Diskon\\n20%", "berlaku\\nhari ini", "#FF8A00"],
        ["Diskon\\n10%", "untuk\\nsemua", "#1DB954"],
      ];
      for (const finalRow of promos) {
        await run(
          db,
          `INSERT INTO promos (title, subtitle, color) VALUES (?,?,?)`,
          finalRow
        );
      }
      console.log("✅ Seed promos inserted");
    }


    console.log("✅ Migration done");
  } catch (e) {
    console.error("❌ Migration error:", e);
    process.exit(1);
  } finally {
    db.close();
  }
})();
