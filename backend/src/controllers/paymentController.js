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
  bankCode,
  itemName,
}) {
  const cfg = midtransConfig();
  if (!cfg) {
    console.warn("Midtrans disabled: MIDTRANS_SERVER_KEY not set.");
    const payment_url = `https://sandbox.example/pay/${orderId}`;
    await run(
      db,
      `UPDATE orders
       SET payment_url = ?, payment_method = ?, bank_code = NULL, va_number = NULL, va_expired_at = NULL,
           biller_code = NULL, bill_key = NULL
       WHERE id = ?`,
      [payment_url, paymentMethod, orderId]
    );
    return {
      payment_url,
      payment_token: null,
      payment_qr: null,
      bank_code: null,
      va_number: null,
      va_expired_at: null,
      biller_code: null,
      bill_key: null,
    };
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
       SET payment_url = ?, payment_qr = ?, payment_method = ?, midtrans_order_id = ?,
           bank_code = NULL, va_number = NULL, va_expired_at = NULL,
           biller_code = NULL, bill_key = NULL
       WHERE id = ?`,
      [actionUrl, qrString, paymentMethod, orderIdStr, orderId]
    );

    return {
      payment_url: actionUrl,
      payment_token: null,
      payment_qr: qrString,
      bank_code: null,
      va_number: null,
      va_expired_at: null,
      biller_code: null,
      bill_key: null,
    };
  }

  if (paymentMethod === "bank_transfer") {
    const bank = (bankCode || "bca").toString().trim().toLowerCase() || "bca";
    const core = new midtransClient.CoreApi({
      isProduction: cfg.isProduction,
      serverKey: cfg.serverKey,
      clientKey: cfg.clientKey,
    });

    let chargeRes = null;
    if (bank === "mandiri") {
      chargeRes = await core.charge({
        payment_type: "echannel",
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
        echannel: {
          bill_info1: "Payment",
          bill_info2: "Online",
        },
      });
    } else {
      chargeRes = await core.charge({
        payment_type: "bank_transfer",
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
        bank_transfer: { bank },
      });
    }

    const vaNumbers = Array.isArray(chargeRes?.va_numbers) ? chargeRes.va_numbers : [];
    let bankCodeResp = null;
    let vaNumber = null;
    if (vaNumbers.length > 0) {
      bankCodeResp = vaNumbers[0]?.bank || null;
      vaNumber = vaNumbers[0]?.va_number || null;
    }
    if (!vaNumber && chargeRes?.permata_va_number) {
      bankCodeResp = bankCodeResp || "permata";
      vaNumber = chargeRes.permata_va_number;
    }
    if (!vaNumber && chargeRes?.bca_va_number) {
      bankCodeResp = bankCodeResp || "bca";
      vaNumber = chargeRes.bca_va_number;
    }
    if (!vaNumber && chargeRes?.bni_va_number) {
      bankCodeResp = bankCodeResp || "bni";
      vaNumber = chargeRes.bni_va_number;
    }
    if (!vaNumber && chargeRes?.bri_va_number) {
      bankCodeResp = bankCodeResp || "bri";
      vaNumber = chargeRes.bri_va_number;
    }
    const vaExpiredAt = chargeRes?.expiry_time || null;
    const billerCode = chargeRes?.biller_code || null;
    const billKey = chargeRes?.bill_key || null;

    await run(
      db,
      `UPDATE orders
       SET payment_url = NULL, payment_qr = NULL, payment_method = ?, midtrans_order_id = ?,
           bank_code = ?, va_number = ?, va_expired_at = ?, biller_code = ?, bill_key = ?
       WHERE id = ?`,
      [
        paymentMethod,
        orderIdStr,
        bankCodeResp || bank,
        vaNumber,
        vaExpiredAt,
        billerCode,
        billKey,
        orderId,
      ]
    );

    return {
      payment_url: null,
      payment_token: null,
      payment_qr: null,
      bank_code: bankCodeResp || bank,
      va_number: vaNumber,
      va_expired_at: vaExpiredAt,
      biller_code: billerCode,
      bill_key: billKey,
    };
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
     SET payment_token = ?, payment_url = ?, payment_method = ?, midtrans_order_id = ?,
         bank_code = NULL, va_number = NULL, va_expired_at = NULL,
         biller_code = NULL, bill_key = NULL
     WHERE id = ?`,
    [res.token, res.redirect_url, paymentMethod, orderIdStr, orderId]
  );

  return {
    payment_url: res.redirect_url,
    payment_token: res.token,
    payment_qr: null,
    bank_code: null,
    va_number: null,
    va_expired_at: null,
    biller_code: null,
    bill_key: null,
  };
}

async function createPayment(req, res) {
  const orderId = Number(req.body.order_id || 0);
  const paymentMethod = (req.body.payment_method || "").toString();
  const bankCode = (req.body.bank_code || "").toString();
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
      bankCode,
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
