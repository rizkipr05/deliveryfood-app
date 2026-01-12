const router = require("express").Router();
const { listProducts } = require("../controllers/productController");

router.get("/products", listProducts);
router.get("/products:i",);

module.exports = router;
