const { openDb, all } = require('../db/sqlite');

async function getPromos(req, res) {
  const db = openDb();
  try {
    const promos = await all(db, `SELECT id, title, description, image_url, valid_until FROM promos ORDER BY id DESC`);
    return res.json({ data: promos });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: 'Server error' });
  } finally {
    db.close();
  }
}

module.exports = { getPromos };