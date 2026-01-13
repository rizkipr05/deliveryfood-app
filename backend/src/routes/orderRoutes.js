const router = require("express").Router();
const { authRequired } = require("../middlewares/auth");
const {
  checkout,
  confirmPayment,
  listOrders,
  cancelOrder,
} = require("../controllers/orderController");
const { createPayment, getPaymentStatus } = require("../controllers/paymentController");

router.post("/checkout", authRequired, checkout);
router.get("/orders", authRequired, listOrders);
router.post("/payments/create", authRequired, createPayment);
router.get("/payments/:id/status", authRequired, getPaymentStatus);
router.post("/orders/:id/confirm-payment", authRequired, confirmPayment);
router.post("/orders/:id/cancel", authRequired, cancelOrder);

module.exports = router;
