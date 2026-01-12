const router = require("express").Router();
const {
  getUlasans,
  postUlasan,
  updateUlasan,
  deleteUlasan,
} = require("../controllers/ulasanController");
const { authRequired } = require("../middlewares/auth");

router.get("/ulasan", getUlasans);
router.post("/ulasan", authRequired, postUlasan);
router.patch("/ulasan/:id", authRequired, updateUlasan);
router.delete("/ulasan/:id", authRequired, deleteUlasan);

module.exports = router;
