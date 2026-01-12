const router = require("express").Router();
const rateLimit = require("express-rate-limit");
const { register, login, me } = require("../controllers/auth2Controller");
const { authRequired } = require("../middlewares/auth");

const limiter = rateLimit({
  windowMs: 60 * 1000,
  limit: 30,
  standardHeaders: true,
  legacyHeaders: false,
});

router.post("/register", limiter, register);
router.post("/login", limiter, login);
router.post("/logout", authRequired, (req, res) => {
  req.logout(() => {
    res.status(200).json({ message: "Logged out successfully" });
  });
});
router.get("/me", authRequired, me);

module.exports = router;