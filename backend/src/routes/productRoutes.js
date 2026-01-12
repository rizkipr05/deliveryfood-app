const router = require("express").Router();
const { listProducts, productDetail } = require("../controllers/productController");
const { authRequired } = require("../middlewares/auth");
const {
  listCart,
  addToCart,
  updateCartItem,
  removeCartItem,
} = require("../controllers/cartController");

router.get("/products", listProducts);
router.get("/products/:id", productDetail);

router.get("/cart", authRequired, listCart);
router.post("/cart/add", authRequired, addToCart);
router.patch("/cart/item/:id", authRequired, updateCartItem);
router.delete("/cart/item/:id", authRequired, removeCartItem);

module.exports = router;
