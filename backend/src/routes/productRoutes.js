const router = require("express").Router();
const { listProducts } = require("../controllers/productController");

router.get("/products", listProducts);

module.exports = router;
