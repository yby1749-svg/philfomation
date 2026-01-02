#!/bin/bash

# Philfomation 개발 환경 시작 스크립트

echo "🚀 Philfomation 개발 환경 시작..."
echo ""

# 프로젝트 루트로 이동
cd ~/Development/Philfomation

# Firebase Functions dependencies 확인
if [ ! -d "firebase/functions/node_modules" ]; then
    echo "📦 Firebase Functions dependencies 설치 중..."
    cd firebase/functions
    npm install
    cd ../..
fi

# Firebase Emulators 시작
echo ""
echo "🔥 Firebase Emulators 시작 중..."
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📊 Firebase Emulator UI:    http://localhost:4000"
echo "  🔥 Firestore:                localhost:8080"
echo "  🔐 Authentication:           localhost:9099"
echo "  📦 Storage:                  localhost:9199"
echo "  ⚡️ Functions:                localhost:5001"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 종료하려면 Ctrl+C를 누르세요"
echo ""

# Emulators 시작 (기존 데이터 import, 종료 시 export)
firebase emulators:start --import=./firebase-data --export-on-exit

echo ""
echo "👋 개발 환경이 종료되었습니다."
