const { openDb, all } = require("../db/sqlite");

async function listProducts(req, res) {
  const db = openDb();
  try {
    const category = (req.query.category || "").toString().trim();
    const q = (req.query.q || "").toString().trim().toLowerCase();

    let sql = `SELECT id,name,category,store,price,rating,image FROM products`;
    const params = [];

    const where = [];
    if (category && category !== "Semua") {
      where.push(`category = ?`);
      params.push(category);
    }
    if (q) {
      where.push(`(LOWER(name) LIKE ? OR LOWER(store) LIKE ?)`);
      params.push(`%${q}%`, `%${q}%`);
    }
    if (where.length) sql += ` WHERE ` + where.join(" AND ");

    sql += ` ORDER BY id DESC`;

    const rows = await all(db, sql, params);
    return res.json({ data: rows });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: "Server error" });
  } finally {
    db.close();
  }
}

module.exports = { listProducts };
