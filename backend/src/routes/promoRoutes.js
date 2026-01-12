const express = require("express");
const { getPromos } = require("../controllers/promoController");

const router = express.Router();

router.get("/promos", getPromos);

module.exports = router;
