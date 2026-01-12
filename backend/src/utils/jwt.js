const jwt = require("jsonwebtoken");

function signAccessToken(payload) {
  const secret = process.env.JWT_SECRET || "change_me";
  // kamu bisa atur expiry sesuka hati
  return jwt.sign(payload, secret, { expiresIn: "7d" });
}

function verifyAccessToken(token) {
  const secret = process.env.JWT_SECRET || "change_me";
  return jwt.verify(token, secret);
}

module.exports = { signAccessToken, verifyAccessToken };
