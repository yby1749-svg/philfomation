#!/bin/bash

echo "⚙️  Philfomation 터미널 Alias 설정..."
echo ""

# .zshrc 또는 .bashrc 찾기
if [ -f ~/.zshrc ]; then
    RC_FILE=~/.zshrc
elif [ -f ~/.bashrc ]; then
    RC_FILE=~/.bashrc
else
    echo "❌ .zshrc 또는 .bashrc 파일을 찾을 수 없습니다."
    exit 1
fi

# Alias 추가
cat >> $RC_FILE << 'EOF'

# ========================================
# Philfomation Aliases
# ========================================
alias pf='cd ~/Development/Philfomation'
alias pf-dev='cd ~/Development/Philfomation && ./Scripts/dev.sh'
alias pf-test='cd ~/Development/Philfomation && ./Scripts/test.sh'
alias pf-deploy='cd ~/Development/Philfomation && ./Scripts/deploy.sh'
alias pf-monitor='cd ~/Development/Philfomation && ./Scripts/monitor.sh'
alias pf-backup='cd ~/Development/Philfomation && ./Scripts/backup.sh'
alias pf-xcode='cd ~/Development/Philfomation && open Philfomation.xcodeproj'
alias fb-ui='open http://localhost:4000'

EOF

echo "✅ Alias 추가 완료: $RC_FILE"
echo ""
echo "📋 사용 가능한 명령어:"
echo "  pf          - 프로젝트 폴더로 이동"
echo "  pf-dev      - 개발 환경 시작"
echo "  pf-test     - 테스트 실행"
echo "  pf-deploy   - Firebase 배포"
echo "  pf-monitor  - 로그 모니터링"
echo "  pf-backup   - 백업 생성"
echo "  pf-xcode    - Xcode 열기"
echo "  fb-ui       - Firebase UI 열기"
echo ""
echo "💡 새 터미널에서 사용하거나, 다음 명령어 실행:"
echo "   source $RC_FILE"
