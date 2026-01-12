async function sendOtpEmail({ to, otp }) {
  // MODE DEV: cukup log
  if ((process.env.APP_ENV || "development") !== "production") {
    console.log(`[DEV MAIL] OTP to ${to}: ${otp}`);
    return;
  }

  // Kalau mau production beneran, kamu bisa pakai nodemailer.
  // Untuk saat ini kita skip agar simpel.
  console.log("Production mailer not configured.");
}

module.exports = { sendOtpEmail };