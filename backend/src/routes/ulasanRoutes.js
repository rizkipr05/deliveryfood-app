const router = require("express").Router();
const { getUlasans, postUlasan } = require("../controllers/ulasanController");

router.get("/ulasan", getUlasans);

module.exports = router;