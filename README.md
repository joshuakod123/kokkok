# 콕콕 (KokKok) - 자격증 관리 앱

![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?style=flat&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=flat&logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=flat&logo=supabase&logoColor=white)

## 📋 프로젝트 소개

**콕콕**은 자격증 관리를 위한 혁신적인 모바일 애플리케이션입니다. 사용자가 자격증 정보를 탐색하고, 목표를 설정하며, 진행 상황을 추적할 수 있는 올인원 솔루션을 제공합니다.

### 🌟 주요 특징

- **📱 직관적인 UI/UX**: 현대적이고 사용자 친화적인 인터페이스
- **🎯 목표 관리**: D-Day 카운터와 함께하는 스마트한 목표 설정
- **🔍 스마트 검색**: 빠르고 정확한 자격증 검색 시스템
- **📊 맞춤형 추천**: AI 기반 개인화된 자격증 추천
- **📈 진행 상황 추적**: 시각적인 대시보드로 학습 진행도 관리
- **🔒 보안**: Supabase 기반의 안전한 사용자 인증

## 🚀 주요 기능

### 🏠 홈 화면
- **개인화된 대시보드**: 사용자 맞춤형 환영 메시지
- **D-Day 카운터**: 가장 가까운 목표 시험일까지의 남은 일수
- **맞춤 추천**: 사용자 전공 기반 자격증 추천
- **인기 급상승**: 실시간 트렌딩 자격증 정보

### 🔍 탐색 화면
- **카테고리별 분류**: IT, 공학, 경영, 어학, 금융 등
- **고급 검색**: 키워드, 카테고리, 정렬 옵션
- **실시간 검색**: 입력과 동시에 결과 표시
- **상세 필터링**: 합격률, 응시자 수, 난이도별 정렬

### 📊 나의 스펙
- **목표 관리**: 시험 목표일 설정 및 D-Day 추적
- **취득 자격증**: 완료된 자격증 관리
- **관심 자격증**: 즐겨찾기 기능
- **통계 대시보드**: 개인 성취도 시각화

### 👤 프로필
- **계정 관리**: 사용자 정보 수정
- **보안 설정**: 비밀번호 변경, 강제 변경 알림
- **데이터 백업**: 자격증 정보 내보내기/가져오기

## 🛠 기술 스택

### Frontend
- **Flutter 3.0+**: 크로스 플랫폼 모바일 개발
- **Dart 3.0+**: 현대적인 프로그래밍 언어
- **Material Design 3**: 최신 디자인 시스템

### Backend & Database
- **Supabase**:
    - PostgreSQL 데이터베이스
    - 실시간 구독
    - 사용자 인증 및 권한 관리
    - Row Level Security (RLS)

### 상태 관리 & 로컬 저장
- **SharedPreferences**: 로컬 데이터 저장
- **Flutter Secure Storage**: 민감한 정보 보안 저장

### UI/UX 라이브러리
- **Google Nav Bar**: 하단 네비게이션
- **Custom Widgets**: 재사용 가능한 컴포넌트들

## 📦 설치 및 실행

### 사전 요구사항
- Flutter SDK 3.0 이상
- Dart SDK 3.0 이상
- Android Studio / Xcode
- Supabase 계정

### 설치 단계

1. **저장소 클론**
```bash
git clone https://github.com/yourusername/kokkok.git
cd kokkok
```

2. **의존성 설치**
```bash
flutter pub get
```

3. **Supabase 설정**
```dart
// lib/main.dart에서 Supabase 정보 업데이트
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```

4. **앱 실행**
```bash
flutter run
```

## 🗄 데이터베이스 스키마

### users 테이블
```sql
CREATE TABLE profiles (
  id UUID REFERENCES auth.users PRIMARY KEY,
  username TEXT NOT NULL,
  user_id TEXT UNIQUE NOT NULL,
  email TEXT,
  major TEXT,
  force_password_change BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### 필요한 RPC 함수들
```sql
-- 사용자 ID로 이메일 찾기
CREATE OR REPLACE FUNCTION get_email_by_userid(input_userid TEXT)
RETURNS TEXT AS $$
-- 함수 내용
$$ LANGUAGE plpgsql;

-- 사용자 ID 중복 확인
CREATE OR REPLACE FUNCTION check_userid_exists(input_userid TEXT)
RETURNS BOOLEAN AS $$
-- 함수 내용
$$ LANGUAGE plpgsql;

-- 비밀번호 재설정
CREATE OR REPLACE FUNCTION reset_password_by_login(login_input TEXT)
RETURNS TEXT AS $$
-- 함수 내용
$$ LANGUAGE plpgsql;
```

## 📱 화면 구성

### 인증 플로우
1. **스플래시 화면**: 앱 로딩
2. **로그인/회원가입**: 통합 인증 화면
3. **비밀번호 찾기**: 임시 비밀번호 발급

### 메인 플로우
1. **홈**: 개인화된 대시보드
2. **탐색**: 자격증 검색 및 브라우징
3. **커뮤니티**: 사용자 상호작용 (준비 중)
4. **나의 스펙**: 개인 자격증 관리
5. **프로필**: 계정 설정

## 🎨 디자인 시스템

### 색상 팔레트
- **Primary**: Deep Purple (#673AB7)
- **Secondary**: Orange (#FF9800)
- **Success**: Green (#4CAF50)
- **Warning**: Orange (#FF9800)
- **Error**: Red (#F44336)

### 타이포그래피
- **Display**: 32px, Bold - 앱 제목용
- **Headline**: 24px, Bold - 섹션 제목
- **Title**: 20px, Bold - 카드 제목
- **Body**: 16px, Regular - 본문
- **Caption**: 12px, Regular - 부가 정보

## 🔧 주요 컴포넌트

### 위젯 구조
```
lib/
├── main.dart                          # 앱 진입점
├── models/
│   └── certification.dart             # 자격증 데이터 모델
├── screens/
│   ├── splash_screen.dart             # 스플래시
│   ├── auth_screen.dart               # 인증
│   ├── main_screen.dart               # 메인 네비게이션
│   ├── enhanced_home_screen.dart      # 홈
│   ├── certification_browse_screen.dart # 탐색
│   ├── my_spec_screen.dart            # 나의 스펙
│   ├── profile_screen.dart            # 프로필
│   └── certification_detail_screen.dart # 자격증 상세
├── widgets/
│   ├── d_day_card.dart                # D-Day 카드
│   ├── recommendation_card.dart        # 추천 카드
│   ├── trending_card.dart             # 트렌딩 카드
│   └── certification_list_tile.dart    # 자격증 리스트 아이템
└── services/
    ├── certification_api_service.dart  # API 서비스
    └── user_certification_service.dart # 사용자 데이터 서비스
```

## 📈 성능 최적화

### 메모리 관리
- **싱글톤 패턴**: 서비스 클래스의 효율적인 인스턴스 관리
- **Lazy Loading**: 필요할 때만 데이터 로드
- **Widget 재사용**: 공통 컴포넌트 모듈화

### 네트워크 최적화
- **캐싱**: SharedPreferences를 통한 로컬 캐싱
- **배치 요청**: 여러 API 호출 최적화
- **에러 핸들링**: 네트워크 실패 시 graceful degradation

## 🔒 보안 고려사항

### 인증 보안
- **JWT 토큰**: Supabase 기반 안전한 토큰 관리
- **비밀번호 정책**: 6자 이상 + 복잡성 요구사항
- **강제 비밀번호 변경**: 임시 비밀번호 사용 시

### 데이터 보안
- **RLS (Row Level Security)**: 데이터베이스 레벨 보안
- **입력 검증**: 클라이언트 및 서버 사이드 검증
- **민감 정보 암호화**: Flutter Secure Storage 활용

## 🚀 향후 개발 계획

### Phase 1 (현재)
- ✅ 기본 자격증 관리 기능
- ✅ 사용자 인증 시스템
- ✅ 목표 설정 및 추적

### Phase 2 (다음 버전)
- 🔄 커뮤니티 기능 구현
- 🔄 실제 자격증 API 연동
- 🔄 푸시 알림 시스템

### Phase 3 (장기)
- 📱 AI 기반 학습 추천
- 📊 상세 분석 대시보드
- 🎯 스터디 그룹 기능

## 🤝 기여 가이드

### 코드 기여
1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

### 코딩 컨벤션
- **Dart 스타일 가이드** 준수
- **명명 규칙**: camelCase for variables, PascalCase for classes
- **주석**: 복잡한 로직에 대한 설명 포함
- **테스트**: 새로운 기능에 대한 테스트 코드 작성

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 📞 연락처

- **개발자**: [Your Name]
- **이메일**: [your.email@example.com]
- **GitHub**: [https://github.com/yourusername]

## 🙏 감사의 말

- **Flutter Team**: 훌륭한 프레임워크 제공
- **Supabase**: 강력한 백엔드 서비스
- **Material Design**: 아름다운 디자인 시스템
- **오픈소스 커뮤니티**: 다양한 패키지와 도구들

---

**콕콕과 함께 당신의 자격증 여정을 시작하세요! 🚀**