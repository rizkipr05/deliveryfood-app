const router = require("express").Router();
const { authRequired } = require("../middlewares/auth");
const { listAddresses, addAddress } = require("../controllers/addressController");

router.get("/addresses", authRequired, listAddresses);
router.post("/addresses", authRequired, addAddress);

module.exports = router;
