const { z } = require("zod");
const { openDb, get, run } = require("../db/sqlite");
const { createPaymentForOrder } = require("./paymentController");

const checkoutSchema = z.object({
  product_id: z.number().int().positive(),
  qty: z.number().int().positive().default(1),
  payment_method: z.enum(["cash", "qris", "bank_transfer"]).default("qris"),
  delivery_method: z.enum(["pickup", "delivery"]).default("pickup"),
  address: z.string().optional(),
  note: z.string().optional(),
});

async function checkout(req, res) {
  const parsed = checkoutSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ message: "Invalid payload" });

  const { product_id, qty, payment_method, delivery_method, address, note } = parsed.data;
  const db = openDb();
  try {
    const product = await get(
      db,
      `SELECT id, name, price, promo_price FROM products WHERE id = ?`,
      [product_id]
    );
    if (!product) return res.status(404).json({ message: "Product not found" });

    const basePrice =
      product.promo_price && product.promo_price > 0 && product.promo_price < product.price
        ? product.promo_price
        : product.price;
    const subtotal = basePrice * qty;
    const deliveryFee = delivery_method === "delivery" ? 5000 : 0;
    const total = subtotal + deliveryFee;

    const orderRes = await run(
      db,
      `
      INSERT INTO orders (
        user_id,
        payment_method,
        delivery_method,
        address,
        note,
        subtotal,
        delivery_fee,
        total
      ) VALUES (?,?,?,?,?,?,?,?)
      `,
      [
        req.user.id,
        payment_method,
        delivery_method,
        (address || "").trim(),
        (note || "").trim(),
        subtotal,
        deliveryFee,
        total,
      ]
    );

    await run(
      db,
      `
      INSERT INTO order_items (order_id, product_id, qty, price, promo_price)
      VALUES (?,?,?,?,?)
      `,
      [orderRes.lastID, product_id, qty, product.price, product.promo_price || null]
    );

    let payment = null;
    if (payment_method !== "cash") {
      payment = await createPaymentForOrder({
        db,
        orderId: orderRes.lastID,
        userId: req.user.id,
        total,
        paymentMethod: payment_method,
        itemName: product.name,
      });
    }

    return res.status(201).json({
      data: {
        id: orderRes.lastID,
        total,
        payment_method,
        delivery_method,
        payment_url: payment?.payment_url || null,
        payment_token: payment?.payment_token || null,
        payment_qr: payment?.payment_qr || null,
      },
    });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: e?.message || "Server error" });
  } finally {
    db.close();
  }
}

async function confirmPayment(req, res) {
  const orderId = Number(req.params.id || 0);
  if (!orderId) return res.status(400).json({ message: "Invalid order id" });

  const db = openDb();
  try {
    const row = await get(
      db,
      `SELECT id FROM orders WHERE id = ? AND user_id = ?`,
      [orderId, req.user.id]
    );
    if (!row) return res.status(404).json({ message: "Order not found" });

    await run(
      db,
      `UPDATE orders SET payment_status = 'paid', status = 'paid' WHERE id = ?`,
      [orderId]
    );
    return res.json({ message: "Payment confirmed" });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: "Server error" });
  } finally {
    db.close();
  }
}

module.exports = { checkout, confirmPayment };
