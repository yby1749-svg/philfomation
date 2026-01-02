#!/bin/bash

echo "💾 Philfomation 백업 시작..."
echo ""

cd ~/Development/Philfomation

# 날짜 생성
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="philfomation_backup_${DATE}.tar.gz"

echo "📦 백업 파일 생성 중: ${BACKUP_NAME}"

# Firebase 데이터와 주요 파일들 백업
tar -czf Backups/${BACKUP_NAME} \
    firebase-data/ \
    firebase/ \
    Philfomation/ \
    Scripts/ \
    README.md \
    .gitignore \
    firebase.json \
    .firebaserc \
    --exclude=node_modules \
    --exclude=.git

echo "✅ 백업 완료: Backups/${BACKUP_NAME}"
echo ""

# 오래된 백업 삭제 (30일 이상)
echo "🧹 오래된 백업 정리..."
find Backups/ -name "*.tar.gz" -mtime +30 -delete

echo "✅ 백업 프로세스 완료!"
