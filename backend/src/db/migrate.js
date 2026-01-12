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

      for (finalRow of seed) {                                          
        await run(
          db,
          `INSERT INTO products (name, category, store, price, rating, image) VALUES (?,?,?,?,?,?)`,
          finalRow
        );
      }
      console.log("✅ Seed products inserted");
    }


    console.log("✅ Migration done");
  } catch (e) {
    console.error("❌ Migration error:", e);
    process.exit(1);
  } finally {
    db.close();
  }
})();
