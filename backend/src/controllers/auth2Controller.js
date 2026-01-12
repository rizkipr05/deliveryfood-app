const bcrypt = require("bcryptjs");
const { z } = require("zod");
const { openDb, run, get } = require("../db/sqlite");
const { signAccessToken } = require("../utils/jwt");

const registerSchema = z.object({
  name: z.string().min(2).max(50),
  email: z.string().email(),
  password: z.string().min(8),
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

async function register(req, res) {
  const parsed = registerSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ message: "Invalid payload" });

  const { name, email, password } = parsed.data;

  const db = openDb();
  try {
    const exists = await get(db, `SELECT id FROM users WHERE email = ?`, [email]);
    if (exists) return res.status(409).json({ message: "Email sudah terdaftar" });

    const passwordHash = await bcrypt.hash(password, 10);

    const result = await run(
      db,
      `INSERT INTO users (name, email, password_hash, role) VALUES (?,?,?,?)`,
      [name, email, passwordHash, "customer"]
    );

    const user = { id: result.lastID, name, email, role: "customer" };
    const token = signAccessToken({ id: user.id, email: user.email, role: user.role });

    return res.status(201).json({
      message: "Register berhasil",
      token,
      user,
    });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: "Server error" });
  } finally {
    db.close();
  }
}

async function login(req, res) {
  const parsed = loginSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ message: "Invalid payload" });

  const { email, password } = parsed.data;

  const db = openDb();
  try {
    const user = await get(
      db,
      `SELECT id, name, email, password_hash, role FROM users WHERE email = ?`,
      [email]
    );

    if (!user) return res.status(401).json({ message: "Email atau password salah" });

    const ok = await bcrypt.compare(password, user.password_hash);
    if (!ok) return res.status(401).json({ message: "Email atau password salah" });

    const token = signAccessToken({ id: user.id, email: user.email, role: user.role });

    return res.json({
      message: "Login berhasil",
      token,
      user: { id: user.id, name: user.name, email: user.email, role: user.role },
    });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: "Server error" });
  } finally {
    db.close();
  }
}

async function me(req, res) {
  // req.user dari middleware
  const db = openDb();
  try {
    const row = await get(db, `SELECT id, name, email, role, created_at FROM users WHERE id = ?`, [
      req.user.id,
    ]);
    if (!row) return res.status(404).json({ message: "User not found" });
    return res.json({ user: row });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: "Server error" });
  } finally {
    db.close();
  }
}

async function logout(req, res) {
  // Since we're using stateless JWTs, logout can be handled on the client side by simply deleting the token.
  return res.json({ message: "Logout berhasil" });
}

module.exports = { register, login, logout, me };
