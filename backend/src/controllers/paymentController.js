const path = require("path");
require("dotenv").config({ path: path.join(__dirname, "..", "..", ".env") });
const midtransClient = require("midtrans-client");
const { openDb, run, get } = require("../db/sqlite");

function midtransConfig() {
  const serverKey = process.env.MIDTRANS_SERVER_KEY || "";
  const clientKey = process.env.MIDTRANS_CLIENT_KEY || "";
  const isProduction = (process.env.MIDTRANS_IS_PRODUCTION || "false") === "true";
  if (!serverKey) return null;
  return { serverKey, clientKey, isProduction };
}

async function createPaymentForOrder({
  db,
  orderId,
  userId,
  total,
  paymentMethod,
  itemName,
}) {
  const cfg = midtransConfig();
  if (!cfg) {
    console.warn("Midtrans disabled: MIDTRANS_SERVER_KEY not set.");
    const payment_url = `https://sandbox.example/pay/${orderId}`;
    await run(
      db,
      `UPDATE orders SET payment_url = ?, payment_method = ? WHERE id = ?`,
      [payment_url, paymentMethod, orderId]
    );
    return { payment_url, payment_token: null, payment_qr: null };
  }

  const orderIdStr = `ORDER-${orderId}-${Date.now()}`;

  if (paymentMethod === "qris") {
    const core = new midtransClient.CoreApi({
      isProduction: cfg.isProduction,
      serverKey: cfg.serverKey,
      clientKey: cfg.clientKey,
    });

    const chargeRes = await core.charge({
      payment_type: "qris",
      transaction_details: {
        order_id: orderIdStr,
        gross_amount: total,
      },
      item_details: [
        {
          id: `product-${orderId}`,
          name: itemName || "Order",
          quantity: 1,
          price: total,
        },
      ],
      qris: { acquirer: "gopay" },
    });

    const actionUrl = chargeRes?.actions?.[0]?.url || null;
    const qrString = chargeRes?.qr_string || null;

    await run(
      db,
      `UPDATE orders
       SET payment_url = ?, payment_qr = ?, payment_method = ?, midtrans_order_id = ?
       WHERE id = ?`,
      [actionUrl, qrString, paymentMethod, orderIdStr, orderId]
    );

    return { payment_url: actionUrl, payment_token: null, payment_qr: qrString };
  }

  const snap = new midtransClient.Snap({
    isProduction: cfg.isProduction,
    serverKey: cfg.serverKey,
  });

  const transaction = {
    transaction_details: {
      order_id: orderIdStr,
      gross_amount: total,
    },
    item_details: [
      {
        id: `product-${orderId}`,
        name: itemName || "Order",
        quantity: 1,
        price: total,
      },
    ],
    enabled_payments:
      paymentMethod === "bank_transfer"
        ? ["bank_transfer"]
        : paymentMethod === "cash"
          ? []
          : undefined,
  };

  const res = await snap.createTransaction(transaction);

  await run(
    db,
    `UPDATE orders
     SET payment_token = ?, payment_url = ?, payment_method = ?, midtrans_order_id = ?
     WHERE id = ?`,
    [res.token, res.redirect_url, paymentMethod, orderIdStr, orderId]
  );

  return { payment_url: res.redirect_url, payment_token: res.token, payment_qr: null };
}

async function createPayment(req, res) {
  const orderId = Number(req.body.order_id || 0);
  const paymentMethod = (req.body.payment_method || "").toString();
  if (!orderId || !paymentMethod) {
    return res.status(400).json({ message: "Invalid payload" });
  }

  const db = req.db || null;
  const localDb = db || openDb();
  try {
    const row = await get(
      localDb,
      `SELECT id, user_id, total FROM orders WHERE id = ?`,
      [orderId]
    );
    if (!row || row.user_id !== req.user.id) {
      return res.status(404).json({ message: "Order not found" });
    }

    const payment = await createPaymentForOrder({
      db: localDb,
      orderId: row.id,
      userId: row.user_id,
      total: row.total,
      paymentMethod,
      itemName: "Order",
    });

    return res.json({ data: payment });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: "Server error" });
  } finally {
    if (!db) localDb.close();
  }
}

async function getPaymentStatus(req, res) {
  const orderId = Number(req.params.id || 0);
  if (!orderId) return res.status(400).json({ message: "Invalid order id" });

  const db = openDb();
  try {
    const order = await get(
      db,
      `SELECT id, user_id, payment_method, payment_status, midtrans_order_id
       FROM orders WHERE id = ?`,
      [orderId]
    );
    if (!order || order.user_id !== req.user.id) {
      return res.status(404).json({ message: "Order not found" });
    }

    if (!order.midtrans_order_id) {
      return res.json({ paid: order.payment_status === "paid", status: order.payment_status });
    }

    const cfg = midtransConfig();
    if (!cfg) {
      return res.json({ paid: false, status: "pending" });
    }

    const core = new midtransClient.CoreApi({
      isProduction: cfg.isProduction,
      serverKey: cfg.serverKey,
      clientKey: cfg.clientKey,
    });

    const statusRes = await core.transaction.status(order.midtrans_order_id);
    const status = statusRes?.transaction_status || "pending";
    const paidStatuses = ["settlement", "capture", "success"];
    const paid = paidStatuses.includes(status);

    if (paid && order.payment_status !== "paid") {
      await run(
        db,
        `UPDATE orders SET payment_status = 'paid', status = 'paid' WHERE id = ?`,
        [orderId]
      );
    }

    return res.json({ paid, status });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: e?.message || "Server error" });
  } finally {
    db.close();
  }
}

module.exports = { createPayment, createPaymentForOrder, getPaymentStatus };
