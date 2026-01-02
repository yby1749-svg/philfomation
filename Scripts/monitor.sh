#!/bin/bash

echo "📊 Philfomation 모니터링..."
echo ""

cd ~/Development/Philfomation

echo "🔥 Firebase Functions 로그:"
firebase functions:log --limit 50

echo ""
echo "📈 실시간 로그 모니터링 (Ctrl+C로 종료):"
firebase functions:log --follow
