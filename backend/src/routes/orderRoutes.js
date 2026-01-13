const router = require("express").Router();
const { authRequired } = require("../middlewares/auth");
const { checkout, confirmPayment } = require("../controllers/orderController");
const { createPayment, getPaymentStatus } = require("../controllers/paymentController");

router.post("/checkout", authRequired, checkout);
router.post("/payments/create", authRequired, createPayment);
router.get("/payments/:id/status", authRequired, getPaymentStatus);
router.post("/orders/:id/confirm-payment", authRequired, confirmPayment);

module.exports = router;
