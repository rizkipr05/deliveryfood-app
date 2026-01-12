const { openDb, all } = require('../db/sqlite');
const { get } = require('../routes/auth2Routes');

async function getPromos(req, res) {
    const db = openDb();
    try {
        const rows = await all(db, `SELECT id, title, description, discount_percentage, valid_until FROM promos ORDER BY id DESC`);
        return res.json({ data: rows });
    } catch (e) {
        console.error(e);
        return res.status(500).json({ message: "Server error" });
    } finally {
        db.close();
    }
}

module.exports = {getPromos}