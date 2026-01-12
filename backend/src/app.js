require("dotenv").config();
const express = require("express");
const cors = require("cors");
const helmet = require("helmet");

const authRoutes = require("./routes/authRoutes");
const auth2Routes = require("./routes/auth2Routes");
const productRoutes = require("./routes/productRoutes");

const app = express();

app.use(helmet());
app.use(cors({ origin: "*"}));
app.use(express.json({ limit: "1mb" }));

app.get("/health", (req, res) => res.json({ ok: true }));

app.use("/api/auth", authRoutes);
app.use("/api/auth2", auth2Routes);
app.use("/api", productRoutes);

app.use((req, res) => res.status(404).json({ message: "Not Found" }));

module.exports = app;
