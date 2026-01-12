const bcrypt = require("bcryptjs");
const { z } = require("zod");
const { openDb, run, get } = require("../db/sqlite");
const { generateOtp, sha256, generateResetToken } = require("../utils/otp");
const { sendOtpEmail } = require("../utils/mailer");

function nowIso() {
  return new Date().toISOString();
}

function addMinutesToIso(min) {
  return new Date(Date.now() + min * 60 * 1000).toISOString();
}

const forgotSchema = z.object({
  email: z.string().email(),
});

const verifySchema = z.object({
  email: z.string().email(),
  otp: z.string().min(4).max(8),
});

const resetSchema = z.object({
  resetToken: z.string().min(20),
  newPassword: z.string().min(8),
  confirmPassword: z.string().min(8),
});

async function forgotPassword(req, res) {
  const parsed = forgotSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ message: "Invalid payload" });

  const { email } = parsed.data;

  const db = openDb();
  try {
    const user = await get(db, `SELECT id, email FROM users WHERE email = ?`, [email]);

    // untuk keamanan: respons tetap sama walau email tidak ada
    if (!user) {
      return res.json({ message: "Jika email terdaftar, OTP akan dikirim." });
    }

    const otp = generateOtp(4);
    const otpHash = sha256(otp);

    const otpTtl = Number(process.env.OTP_TTL_MINUTES || 2);
    const expiresAt = addMinutesToIso(otpTtl);

    // buat entry reset baru
    await run(
      db,
      `
      INSERT INTO password_resets (user_id, otp_hash, expires_at, attempts, verified, created_at)
      VALUES (?, ?, ?, 0, 0, ?)
      `,
      [user.id, otpHash, expiresAt, nowIso()]
    );

    await sendOtpEmail({ to: email, otp });

    // DEV: biar Flutter gampang test, return otp (hapus kalau production)
    const devOtp = (process.env.APP_ENV || "development") !== "production" ? otp : undefined;

    return res.json({ message: "OTP dikirim.", devOtp, expiresAt });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: "Server error" });
  } finally {
    db.close();
  }
}

async function verifyOtp(req, res) {
  const parsed = verifySchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ message: "Invalid payload" });

  const { email, otp } = parsed.data;

  const db = openDb();
  try {
    const user = await get(db, `SELECT id FROM users WHERE email = ?`, [email]);
    if (!user) return res.status(400).json({ message: "OTP tidak valid." });

    // ambil reset terbaru yang belum verified
    const reset = await get(
      db,
      `
      SELECT * FROM password_resets
      WHERE user_id = ? AND verified = 0
      ORDER BY id DESC
      LIMIT 1
      `,
      [user.id]
    );

    if (!reset) return res.status(400).json({ message: "OTP tidak valid." });

    // cek expired
    if (new Date(reset.expires_at).getTime() < Date.now()) {
      return res.status(400).json({ message: "OTP sudah kadaluarsa." });
    }

    // batasi attempt
    if (reset.attempts >= 5) {
      return res.status(429).json({ message: "Terlalu banyak percobaan. Minta OTP baru." });
    }

    const otpHash = sha256(otp);
    if (otpHash !== reset.otp_hash) {
      await run(db, `UPDATE password_resets SET attempts = attempts + 1 WHERE id = ?`, [reset.id]);
      return res.status(400).json({ message: "OTP tidak valid." });
    }

    // OTP valid → buat reset token
    const resetToken = generateResetToken();
    const resetTokenHash = sha256(resetToken);

    const ttl = Number(process.env.RESET_TOKEN_TTL_MINUTES || 15);
    const resetTokenExpiresAt = addMinutesToIso(ttl);

    await run(
      db,
      `
      UPDATE password_resets
      SET verified = 1,
          reset_token_hash = ?,
          reset_token_expires_at = ?
      WHERE id = ?
      `,
      [resetTokenHash, resetTokenExpiresAt, reset.id]
    );

    return res.json({
      message: "OTP valid.",
      resetToken,
      resetTokenExpiresAt,
    });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: "Server error" });
  } finally {
    db.close();
  }
}

async function resetPassword(req, res) {
  const parsed = resetSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ message: "Invalid payload" });

  const { resetToken, newPassword, confirmPassword } = parsed.data;
  if (newPassword !== confirmPassword) {
    return res.status(400).json({ message: "Konfirmasi password tidak sama." });
  }

  const db = openDb();
  try {
    const tokenHash = sha256(resetToken);

    // cari reset token yang valid
    const row = await get(
      db,
      `
      SELECT pr.*, u.id AS uid, u.email AS email
      FROM password_resets pr
      JOIN users u ON u.id = pr.user_id
      WHERE pr.reset_token_hash = ?
      ORDER BY pr.id DESC
      LIMIT 1
      `,
      [tokenHash]
    );

    if (!row) return res.status(400).json({ message: "Reset token tidak valid." });

    if (!row.reset_token_expires_at || new Date(row.reset_token_expires_at).getTime() < Date.now()) {
      return res.status(400).json({ message: "Reset token sudah kadaluarsa." });
    }

    const hash = await bcrypt.hash(newPassword, 10);

    await run(db, `UPDATE users SET password_hash = ? WHERE id = ?`, [hash, row.uid]);

    // invalidate token biar sekali pakai
    await run(
      db,
      `UPDATE password_resets SET reset_token_hash = NULL, reset_token_expires_at = NULL WHERE id = ?`,
      [row.id]
    );

    return res.json({ message: "Password berhasil diubah." });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: "Server error" });
  } finally {
    db.close();
  }
}

module.exports = { forgotPassword, verifyOtp, resetPassword };
