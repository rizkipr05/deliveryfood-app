const { z } = require("zod");
const { openDb, all, get, run } = require("../db/sqlite");

const addSchema = z.object({
  title: z.string().min(1),
  detail: z.string().min(1),
  is_primary: z.boolean().optional(),
});

async function listAddresses(req, res) {
  const db = openDb();
  try {
    const rows = await all(
      db,
      `
      SELECT id, title, detail, is_primary, created_at
      FROM addresses
      WHERE user_id = ?
      ORDER BY is_primary DESC, id DESC
      `,
      [req.user.id]
    );
    return res.json({ data: rows });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: "Server error" });
  } finally {
    db.close();
  }
}

async function addAddress(req, res) {
  const parsed = addSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ message: "Invalid payload" });

  const { title, detail } = parsed.data;
  const db = openDb();
  try {
    const row = await get(
      db,
      `SELECT COUNT(*) as cnt FROM addresses WHERE user_id = ?`,
      [req.user.id]
    );
    let isPrimary = parsed.data.is_primary === true;
    if ((row?.cnt || 0) === 0) isPrimary = true;

    if (isPrimary) {
      await run(db, `UPDATE addresses SET is_primary = 0 WHERE user_id = ?`, [
        req.user.id,
      ]);
    }

    await run(
      db,
      `
      INSERT INTO addresses (user_id, title, detail, is_primary)
      VALUES (?, ?, ?, ?)
      `,
      [req.user.id, title.trim(), detail.trim(), isPrimary ? 1 : 0]
    );
    return res.status(201).json({ message: "Alamat ditambahkan" });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: "Server error" });
  } finally {
    db.close();
  }
}

module.exports = { listAddresses, addAddress };
