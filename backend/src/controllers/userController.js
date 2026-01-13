const { z } = require("zod");
const { openDb, get, run } = require("../db/sqlite");

const updateSchema = z.object({
  name: z.string().min(2),
  phone: z.string().optional(),
  avatar_url: z.string().optional(),
});

async function updateMe(req, res) {
  const parsed = updateSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ message: "Invalid payload" });

  const { name, phone, avatar_url } = parsed.data;
  const db = openDb();
  try {
    const row = await get(db, `SELECT id FROM users WHERE id = ?`, [req.user.id]);
    if (!row) return res.status(404).json({ message: "User not found" });

    await run(
      db,
      `UPDATE users SET name = ?, phone = ?, avatar_url = ? WHERE id = ?`,
      [name.trim(), (phone || "").trim(), (avatar_url || "").trim(), req.user.id]
    );

    const updated = await get(
      db,
      `SELECT id, name, email, role, phone, avatar_url, created_at FROM users WHERE id = ?`,
      [req.user.id]
    );
    return res.json({ user: updated });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: e?.message || "Server error" });
  } finally {
    db.close();
  }
}

module.exports = { updateMe };
