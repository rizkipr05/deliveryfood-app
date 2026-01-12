const { z } = require("zod");
const { openDb, run, get, all } = require("../db/sqlite");

const addSchema = z.object({
  product_id: z.number().int().positive(),
  qty: z.number().int().positive().default(1),
});

const updateSchema = z.object({
  qty: z.number().int().min(1),
});

async function listCart(req, res) {
  const db = openDb();
  try {
    const rows = await all(
      db,
      `
      SELECT
        ci.id AS cart_id,
        ci.product_id,
        ci.qty,
        p.name,
        p.store,
        p.price,
        p.rating,
        p.image
      FROM cart_items ci
      JOIN products p ON p.id = ci.product_id
      WHERE ci.user_id = ?
      ORDER BY ci.id DESC
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

async function addToCart(req, res) {
  const parsed = addSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ message: "Invalid payload" });

  const { product_id, qty } = parsed.data;
  const db = openDb();
  try {
    const exists = await get(
      db,
      `SELECT id, qty FROM cart_items WHERE user_id = ? AND product_id = ?`,
      [req.user.id, product_id]
    );

    if (exists) {
      await run(
        db,
        `UPDATE cart_items SET qty = qty + ?, updated_at = datetime('now') WHERE id = ?`,
        [qty, exists.id]
      );
    } else {
      await run(
        db,
        `
        INSERT INTO cart_items (user_id, product_id, qty)
        VALUES (?, ?, ?)
        `,
        [req.user.id, product_id, qty]
      );
    }

    return res.json({ message: "Added to cart" });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: "Server error" });
  } finally {
    db.close();
  }
}

async function updateCartItem(req, res) {
  const parsed = updateSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ message: "Invalid payload" });

  const cartId = Number(req.params.id || 0);
  if (!cartId) return res.status(400).json({ message: "Invalid cart id" });

  const db = openDb();
  try {
    const row = await get(
      db,
      `SELECT id FROM cart_items WHERE id = ? AND user_id = ?`,
      [cartId, req.user.id]
    );
    if (!row) return res.status(404).json({ message: "Cart item not found" });

    await run(
      db,
      `UPDATE cart_items SET qty = ?, updated_at = datetime('now') WHERE id = ?`,
      [parsed.data.qty, cartId]
    );

    return res.json({ message: "Updated" });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: "Server error" });
  } finally {
    db.close();
  }
}

async function removeCartItem(req, res) {
  const cartId = Number(req.params.id || 0);
  if (!cartId) return res.status(400).json({ message: "Invalid cart id" });

  const db = openDb();
  try {
    const row = await get(
      db,
      `SELECT id FROM cart_items WHERE id = ? AND user_id = ?`,
      [cartId, req.user.id]
    );
    if (!row) return res.status(404).json({ message: "Cart item not found" });

    await run(db, `DELETE FROM cart_items WHERE id = ?`, [cartId]);
    return res.json({ message: "Removed" });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: "Server error" });
  } finally {
    db.close();
  }
}

module.exports = { listCart, addToCart, updateCartItem, removeCartItem };
