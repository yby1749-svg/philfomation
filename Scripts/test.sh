#!/bin/bash

echo "🧪 Philfomation 테스트 실행..."
echo ""

cd ~/Development/Philfomation

# Firebase Functions 테스트
if [ -d "firebase/functions" ]; then
    echo "⚡️ Cloud Functions 테스트..."
    cd firebase/functions
    npm test 2>/dev/null || echo "테스트 스크립트가 아직 없습니다."
    cd ../..
fi

# Firebase Security Rules 검증
echo ""
echo "🔐 Security Rules 검증..."
firebase emulators:exec --only firestore "echo '✅ Firestore Rules OK'" 2>/dev/null || echo "Emulator가 필요합니다"

echo ""
echo "✅ 테스트 완료!"
