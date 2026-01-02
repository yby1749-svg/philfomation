# Philfomation 시작하기

## 🎉 프로젝트 생성 완료!

안전성 검사를 통과하고 Philfomation 프로젝트가 성공적으로 생성되었습니다.

## ✅ 생성된 것들

### 1. 프로젝트 구조
```
Philfomation/
├── App/                    # 앱 진입점
├── Models/                 # 데이터 모델
├── Views/                  # UI 뷰
├── ViewModels/             # 뷰모델
├── Services/               # 서비스 레이어
├── Utils/                  # 유틸리티
└── Resources/              # 리소스 (로고 포함!)
```

### 2. Firebase 설정
- ✅ `firebase.json` - Firebase 설정
- ✅ `firestore.rules` - Firestore 보안 규칙
- ✅ `firestore.indexes.json` - Firestore 인덱스
- ✅ `storage.rules` - Storage 보안 규칙
- ✅ `functions/index.js` - Cloud Functions

### 3. 자동화 스크립트
- ✅ `dev.sh` - 개발 환경 시작
- ✅ `test.sh` - 테스트 실행
- ✅ `deploy.sh` - 배포
- ✅ `monitor.sh` - 로그 모니터링
- ✅ `backup.sh` - 백업 생성
- ✅ `setup-aliases.sh` - 터미널 alias 설정

### 4. 로고 파일
- ✅ 앱 아이콘 (512x512, 1024x1024)
- ✅ 가로형/세로형 로고
- ✅ 다크 모드 버전
- ✅ 흑백 버전

## 🚀 다음 단계

### 1. 터미널 Alias 설정 (선택사항)
```bash
cd ~/Development/Philfomation/Scripts
./setup-aliases.sh
source ~/.zshrc  # 또는 source ~/.bashrc
```

### 2. Firebase 프로젝트 연결
```bash
# Firebase 콘솔에서 프로젝트 생성
# https://console.firebase.google.com

# Firebase CLI 로그인
firebase login

# 프로젝트 선택
cd ~/Development/Philfomation
firebase use --add

# 프로젝트 ID 입력: philfomation
# Alias 입력: default
```

### 3. Cloud Functions Dependencies 설치
```bash
cd ~/Development/Philfomation/firebase/functions
npm install
```

### 4. 개발 환경 시작
```bash
cd ~/Development/Philfomation/Scripts
./dev.sh

# 또는 alias 설정 후
pf-dev
```

### 5. Xcode 프로젝트 생성

Xcode에서 새 프로젝트 생성:
1. Xcode 열기
2. "Create a new Xcode project"
3. "iOS" → "App" 선택
4. Product Name: `Philfomation`
5. Organization Identifier: `com.philfomation`
6. Interface: `SwiftUI`
7. Language: `Swift`
8. Location: `~/Development/Philfomation/`

### 6. Firebase SDK 추가

Swift Package Manager로 Firebase 추가:
1. Xcode에서 File → Add Package Dependencies
2. URL: `https://github.com/firebase/firebase-ios-sdk`
3. Version: "Up to Next Major" (최신 버전)
4. 선택할 Products:
   - FirebaseAuth
   - FirebaseFirestore
   - FirebaseStorage
   - FirebaseMessaging

### 7. GoogleService-Info.plist 추가

1. Firebase Console → Project Settings
2. iOS 앱 추가
3. Bundle ID: `com.philfomation.Philfomation`
4. `GoogleService-Info.plist` 다운로드
5. Xcode 프로젝트에 추가

## 📱 개발 시작

### 일일 워크플로우
```bash
# 1. 개발 환경 시작
pf-dev

# 2. 새 터미널에서 Xcode 열기
pf-xcode

# 3. 코드 작성 및 테스트

# 4. 커밋
git add .
git commit -m "Add feature"

# 5. 백업 (선택사항)
pf-backup
```

### Firebase Emulator UI 접속
```
http://localhost:4000
```

### 주요 포트
- Firebase UI: 4000
- Firestore: 8080
- Authentication: 9099
- Storage: 9199
- Functions: 5001

## 📚 유용한 명령어

```bash
# 프로젝트로 이동
pf

# 개발 환경 시작
pf-dev

# 테스트 실행
pf-test

# Firebase 배포
pf-deploy

# 로그 확인
pf-monitor

# 백업 생성
pf-backup

# Xcode 열기
pf-xcode

# Firebase UI 열기
fb-ui
```

## 🔧 트러블슈팅

### Firebase Emulators가 시작되지 않을 때
```bash
# 포트 사용 확인
lsof -i :4000
lsof -i :8080

# 프로세스 종료
kill -9 <PID>
```

### Dependencies 설치 오류
```bash
cd firebase/functions
rm -rf node_modules
npm install
```

## 📖 더 읽어보기

- [README.md](../README.md) - 프로젝트 전체 개요
- [Firebase 문서](https://firebase.google.com/docs)
- [SwiftUI 튜토리얼](https://developer.apple.com/tutorials/swiftui)

## 🎯 8주 MVP 로드맵

Week 1-2: 기본 인프라
Week 3-4: 핵심 기능
Week 5-6: 고급 기능
Week 7-8: 테스트 & 배포

상세 내용은 README.md 참조

---

**행운을 빕니다! 🚀**
