const path = require("path");
require("dotenv").config({ path: path.join(__dirname, "..", ".env") });
const express = require("express");
const cors = require("cors");
const helmet = require("helmet");

const authRoutes = require("./routes/authRoutes");
const auth2Routes = require("./routes/auth2Routes");
const productRoutes = require("./routes/productRoutes");
const ulasanRoutes = require("./routes/ulasanRoutes");
const promoRoutes = require("./routes/promoRoutes");
const orderRoutes = require("./routes/orderRoutes");

const app = express();

app.use(helmet());
app.use(cors({ origin: "*"}));
app.use(express.json({ limit: "1mb" }));

app.get("/health", (req, res) => res.json({ ok: true }));

app.use("/api/auth", authRoutes);
app.use("/api/auth2", auth2Routes);
app.use("/api", productRoutes);
app.use("/api", ulasanRoutes);
app.use("/api", promoRoutes);
app.use("/api", orderRoutes);

app.use((req, res) => res.status(404).json({ message: "Not Found" }));

module.exports = app;
