const crypto = require("crypto");

function generateOtp(length = 4) {
  let otp = "";
  for (let i = 0; i < length; i++) otp += Math.floor(Math.random() * 10).toString();
  return otp;
}

function sha256(text) {
  return crypto.createHash("sha256").update(text).digest("hex");
}

function generateResetToken() {
  return crypto.randomBytes(32).toString("hex");
}

module.exports = { generateOtp, sha256, generateResetToken };
