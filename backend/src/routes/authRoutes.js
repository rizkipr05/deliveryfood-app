const router = require('express').Router();
const ratelimit = require('express-rate-limit');
const { forgotPassword, verifyOtp, resetPassword } = require("../controllers/authController");

const forgotPasswordLimiter = ratelimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5,
  message: "Too many password reset requests from this IP, please try again later."
});

router.post('/forgot-password', forgotPasswordLimiter, forgotPassword);
router.post('/verify-otp', verifyOtp);
router.post('/reset-password', resetPassword);

module.exports = router;