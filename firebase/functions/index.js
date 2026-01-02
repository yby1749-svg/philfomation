const { onRequest } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");

initializeApp();

// 기본 헬스체크 함수
exports.healthCheck = onRequest((req, res) => {
  res.json({
    status: "ok",
    timestamp: new Date().toISOString(),
    message: "Philfomation API is running",
  });
});
