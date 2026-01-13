const router = require("express").Router();
const { authRequired } = require("../middlewares/auth");
const { updateMe } = require("../controllers/userController");

router.put("/users/me", authRequired, updateMe);

module.exports = router;
