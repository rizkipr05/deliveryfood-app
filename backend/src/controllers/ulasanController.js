const { z } = require("zod");
const { openDb, all, get, run } = require("../db/sqlite");

const addSchema = z.object({
  product_id: z.number().int().positive(),
  star: z.number().int().min(1).max(5),
  comment: z.string().optional(),
});

const updateSchema = z.object({
  star: z.number().int().min(1).max(5),
  comment: z.string().optional(),
});

async function getUlasans(req, res) {
  const productId = Number(req.query.product_id || 0);
  if (!productId) return res.status(400).json({ message: "Invalid product_id" });

  const db = openDb();
  try {
    const rows = await all(
      db,
      `
      SELECT
        ul.id,
        ul.user_id,
        u.name,
        ul.star,
        ul.comment,
        ul.created_at
      FROM ulasan ul
      JOIN users u ON u.id = ul.user_id
      WHERE ul.product_id = ?
      ORDER BY ul.id DESC
      `,
      [productId]
    );
    return res.json({ data: rows });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: "Server error" });
  } finally {
    db.close();
  }
}

async function postUlasan(req, res) {
  const parsed = addSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ message: "Invalid payload" });

  const { product_id, star, comment } = parsed.data;
  const db = openDb();
  try {
    const product = await get(db, `SELECT id FROM products WHERE id = ?`, [product_id]);
    if (!product) return res.status(404).json({ message: "Product not found" });

    await run(
      db,
      `
      INSERT INTO ulasan (user_id, product_id, star, comment)
      VALUES (?, ?, ?, ?)
      `,
      [req.user.id, product_id, star, (comment || "").trim()]
    );

    return res.status(201).json({ message: "Ulasan ditambahkan" });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: "Server error" });
  } finally {
    db.close();
  }
}

async function updateUlasan(req, res) {
  const parsed = updateSchema.safeParse({
    star: req.body.star,
    comment: req.body.comment,
  });
  if (!parsed.success) return res.status(400).json({ message: "Invalid payload" });

  const ulasanId = Number(req.params.id || 0);
  if (!ulasanId) return res.status(400).json({ message: "Invalid ulasan id" });

  const db = openDb();
  try {
    const row = await get(
      db,
      `SELECT id FROM ulasan WHERE id = ? AND user_id = ?`,
      [ulasanId, req.user.id]
    );
    if (!row) return res.status(404).json({ message: "Ulasan not found" });

    await run(
      db,
      `UPDATE ulasan SET star = ?, comment = ? WHERE id = ?`,
      [parsed.data.star, (parsed.data.comment || "").trim(), ulasanId]
    );
    return res.json({ message: "Ulasan updated" });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: "Server error" });
  } finally {
    db.close();
  }
}

async function deleteUlasan(req, res) {
  const ulasanId = Number(req.params.id || 0);
  if (!ulasanId) return res.status(400).json({ message: "Invalid ulasan id" });

  const db = openDb();
  try {
    const row = await get(
      db,
      `SELECT id FROM ulasan WHERE id = ? AND user_id = ?`,
      [ulasanId, req.user.id]
    );
    if (!row) return res.status(404).json({ message: "Ulasan not found" });

    await run(db, `DELETE FROM ulasan WHERE id = ?`, [ulasanId]);
    return res.json({ message: "Ulasan deleted" });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: "Server error" });
  } finally {
    db.close();
  }
}

module.exports = { getUlasans, postUlasan, updateUlasan, deleteUlasan };
