const { openDb, all } = require("../db/sqlite");

async function getPromos(req, res) {
  const db = openDb();
  try {
    const rows = await all(
      db,
      `
      SELECT id, title, subtitle, color
      FROM promos
      ORDER BY id DESC
      `
    );
    return res.json({ data: rows });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: "Server error" });
  } finally {
    db.close();
  }
}

module.exports = { getPromos };
