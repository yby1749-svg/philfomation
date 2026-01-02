#!/bin/bash

echo "🚀 Philfomation 배포 시작..."
echo ""

cd ~/Development/Philfomation

# 배포 전 확인
echo "📋 배포 전 체크리스트:"
read -p "   1. 모든 변경사항이 커밋되었나요? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ 먼저 변경사항을 커밋해주세요."
    exit 1
fi

read -p "   2. 테스트를 모두 통과했나요? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ 먼저 테스트를 실행해주세요."
    exit 1
fi

# Firebase 배포
echo ""
echo "🔥 Firebase 배포 중..."
firebase deploy

echo ""
echo "✅ 배포 완료!"
