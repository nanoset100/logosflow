# BrandingGuide: AI 말씀비서
## 브랜딩 가이드 v1.0

---

## 1. 브랜드 아키텍처

```
┌─────────────────────────────────────────────┐
│              AI 말씀비서 플랫폼              │
│           (Parent Brand / B2B)              │
└──────────────────┬──────────────────────────┘
                   │
        ┌──────────┴──────────┐
        │                     │
┌───────▼────────┐   ┌────────▼───────┐
│ 침신 말씀노트  │   │   말씀브릿지   │
│ Chimshin Bible │   │   WordBridge   │
│    Note        │   │               │
│                │   │               │
│  침례교 전용   │   │  범용 교회용  │
└────────────────┘   └───────────────┘
```

---

## 2. 브랜드 아이덴티티

### 2.1 침신 말씀노트

**브랜드 에센스**
```
핵심 단어: 신뢰, 성장, 따뜻함, 연결
한 줄 정의: "침례교 성도의 일상을 말씀으로 채우는 AI 동반자"
```

**브랜드 성격 (Brand Personality)**
```
1. 따뜻한 멘토 (Warm Mentor)
   - 판단하지 않고 격려하는
   - 내 상황을 이해하는
   - 함께 걸어가는

2. 신뢰할 수 있는 (Trustworthy)
   - 침신대 공식 파트너
   - 신학적으로 검증된
   - 개인정보 안전 보호

3. 접근하기 쉬운 (Approachable)
   - 어른도 쉽게 사용
   - 복잡하지 않은
   - 친근한 언어
```

**브랜드 보이스 (Brand Voice)**
```
톤 스펙트럼:
따뜻함  ●────────────────  차가움
격식체  ──────────●──────  친근체
종교적  ───────────●─────  세속적
복잡함  ─────────────●───  단순함

사용 언어:
✅ "~하세요" (존댓말, 격려)
✅ "함께 ~해봐요"
✅ "~하셨군요! 잘하셨어요"
✅ 이모지 1-2개 (☺️ ✨ 🙏)

❌ "~해야 합니다" (명령)
❌ "실패하셨습니다"
❌ 복잡한 신학 용어
❌ 영어 남발
```

---

### 2.2 말씀브릿지

**브랜드 에센스**
```
핵심 단어: 연결, 보편성, 신뢰, 변화
한 줄 정의: "설교와 삶 사이의 다리"
```

**로고 컨셉**
```
시각적 컨셉:

  말씀 ══════════════ 삶
         (브릿지)

십자가 형태의 다리 또는
말씀 + 생활 아이콘이 연결된 형태

심볼 아이디어:
  ✝ + ─── = 브릿지 형태
  📖 + 🌱 = 말씀이 삶으로
```

---

## 3. 컬러 시스템

### 3.1 침신 말씀노트 컬러

**Primary Palette**
```
┌─────────────────────────────────────────────┐
│                                             │
│  ████████  Trust Blue                       │
│  #4A90E2   Primary 브랜드 컬러              │
│  R:74 G:144 B:226                           │
│  사용: 주요 버튼, 링크, 강조 텍스트         │
│                                             │
│  ████████  Growth Green                     │
│  #7ED321   Secondary 컬러                   │
│  R:126 G:211 B:33                           │
│  사용: 완료 체크, 진행 바, 성공 상태        │
│                                             │
│  ████████  Blessing Gold                    │
│  #F5A623   Accent 컬러                      │
│  R:245 G:166 B:35                           │
│  사용: 특별 성취, 배지, 강조 포인트         │
│                                             │
└─────────────────────────────────────────────┘
```

**Neutral Palette**
```
████████  Deep Navy       #2C3E50  (제목 텍스트)
████████  Text Gray       #5D6D7E  (본문 텍스트)
████████  Sub Gray        #95A5A6  (서브 텍스트)
████████  Border          #E8ECF0  (구분선)
████████  Background      #F8F9FA  (앱 배경)
████████  White           #FFFFFF  (카드 배경)
```

**Semantic Colors**
```
████████  Success    #27AE60  (완료, 성공)
████████  Warning    #F39C12  (주의, 미완료)
████████  Error      #E74C3C  (오류, 경고)
████████  Info       #3498DB  (정보, 알림)
```

**컬러 사용 비율**
```
기본 배경 (White/Background):  70%
Primary Blue:                  20%
Secondary Green:                5%
Accent Gold + 기타:             5%
```

### 3.2 말씀브릿지 컬러

```
Primary:   #5B7FDB  Bridge Blue  (침신과 다른 블루)
Secondary: #4CAF8A  Life Green
Accent:    #E8935A  Warmth Orange
```

---

## 4. 타이포그래피

### 4.1 폰트 선택

```
국문 폰트: Pretendard (공개 라이선스)
영문 폰트: SF Pro (iOS) / Roboto (Android) - 시스템 기본

이유:
- Pretendard: 가독성 최고, 어른 친화적
- 둥글고 따뜻한 형태
- 다양한 굵기 지원
- 무료 사용 가능
```

### 4.2 타입 스케일

```dart
// Flutter 텍스트 테마

TextTheme(
  // 헤드라인
  displayLarge: TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,    // 700
    color: Color(0xFF2C3E50),
    height: 1.3,
  ),
  headlineLarge: TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Color(0xFF2C3E50),
    height: 1.3,
  ),
  headlineMedium: TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,    // SemiBold
    color: Color(0xFF2C3E50),
    height: 1.4,
  ),
  headlineSmall: TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: Color(0xFF2C3E50),
    height: 1.4,
  ),

  // 본문 (어른 친화적 - 최소 18pt)
  bodyLarge: TextStyle(
    fontSize: 18,                   // ← 최소 크기
    fontWeight: FontWeight.normal,  // 400
    color: Color(0xFF5D6D7E),
    height: 1.6,                    // 넉넉한 행간
  ),
  bodyMedium: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Color(0xFF5D6D7E),
    height: 1.6,
  ),

  // 레이블 (버튼, 탭)
  labelLarge: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  ),
  labelMedium: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  ),
)
```

### 4.3 성경 구절 스타일 (특별)

```dart
// 성경 구절 강조 스타일
const bibleVerseStyle = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w500,
  fontStyle: FontStyle.italic,    // 이탤릭으로 구분
  color: Color(0xFF2C5282),       // 진한 파란색
  height: 1.7,
  letterSpacing: 0.3,
);

const bibleReferenceStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: Color(0xFF4A90E2),
);
```

---

## 5. 아이콘 & 일러스트레이션

### 5.1 아이콘 시스템

```
메인 아이콘 세트: Material Symbols (Google)
이유:
- 일관된 디자인 언어
- 한국 사용자에게 친숙
- 다양한 스타일 (Outlined/Filled)
- 무료

핵심 아이콘:
┌──────────────────────────────────────┐
│ 기능          아이콘         스타일  │
├──────────────────────────────────────┤
│ 홈            home          Filled   │
│ 설교          menu_book     Outlined │
│ 묵상/기록     bar_chart     Outlined │
│ 더보기        menu          Outlined │
│ 완료          check_circle  Filled   │
│ 미완료        radio_button  Outlined │
│ 알림          notifications Outlined │
│ 설정          settings      Outlined │
│ 목사대시보드  dashboard     Outlined │
│ 간증          chat_bubble   Outlined │
│ 기도          volunteer_activism Outlined│
│ 공유          share         Outlined │
└──────────────────────────────────────┘
```

### 5.2 이모지 사용 가이드

```
허용 이모지 (따뜻하고 종교적):
✅ ✨ 🌱 🙏 📖 ✝️ 💝 🌟 🎉 💪 ☀️ 🌅 🌙 🔥

금지 이모지:
❌ 세속적이거나 부적절한 이모지
❌ 과도한 이모지 사용 (2개 이상 연속)
❌ 단독 이모지만으로 메시지 전달

사용 원칙:
- 메시지 앞 또는 뒤에 1개
- 강조할 때만 사용
- 텍스트가 주, 이모지는 보조
```

### 5.3 일러스트레이션 스타일

```
스타일 가이드:
- 따뜻한 색조 (파스텔 + 원색)
- 사람 얼굴 표현 (다양한 연령대)
- 한국인 외모 반영
- 교회/신앙 관련 요소 (십자가, 성경, 빛)
- 과도한 애니메이션 지양

사용처:
- 온보딩 화면 3장
- 빈 상태 화면 (데이터 없을 때)
- 완료/축하 화면
- 오류 화면

제작 도구: Figma + 벡터 일러스트
외주 또는 AI 이미지 생성 (저작권 확인 필수)
```

---

## 6. 로고 가이드

### 6.1 침신 말씀노트 로고

```
로고 구성:
[심볼] + [워드마크]

심볼 컨셉:
   ┌─────┐
   │  ✝  │   십자가가 책 위에 = 말씀 + 신앙
   │ 📖  │
   └─────┘

또는:

   ┌─────┐
   │  ✝  │   십자가가 노트 = 말씀 기록
   │ 📝  │
   └─────┘

워드마크:
침신 말씀노트
(Pretendard Bold, 두 줄 또는 한 줄)

색상 버전:
1. 컬러: Trust Blue 배경 + 흰색 심볼/텍스트
2. 화이트: 흰색 배경 + Trust Blue
3. 모노: 흰색 배경 + 검정
```

### 6.2 로고 사용 규칙

```
최소 크기:
- 앱 아이콘: 1024×1024px (원본)
- 인쇄: 최소 30mm
- 디지털: 최소 120px

여백 (클리어 스페이스):
로고 높이의 1/4 이상 여백 확보

금지 사항:
❌ 로고 변형 (늘리기, 기울이기)
❌ 비브랜드 색상 적용
❌ 반투명 처리
❌ 배경과 대비 낮은 사용
❌ 로고 위에 텍스트 겹침
```

---

## 7. UI 컴포넌트 스타일 가이드

### 7.1 버튼 스타일

```dart
// Primary Button
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Color(0xFF4A90E2),  // Trust Blue
    foregroundColor: Colors.white,
    minimumSize: Size(double.infinity, 56),  // 큰 터치 영역
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 0,
    textStyle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
  ),
)

// Secondary Button
OutlinedButton(
  style: OutlinedButton.styleFrom(
    foregroundColor: Color(0xFF4A90E2),
    minimumSize: Size(double.infinity, 48),
    side: BorderSide(color: Color(0xFF4A90E2), width: 1.5),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
)

// 완료 버튼 (Success)
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Color(0xFF7ED321),  // Growth Green
    minimumSize: Size(double.infinity, 56),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
)
```

### 7.2 카드 스타일

```dart
// 설교 카드
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
  ),
  padding: EdgeInsets.all(20),
)

// 격려 메시지 카드
Container(
  decoration: BoxDecoration(
    color: Color(0xFFEBF5FF),   // 연한 파란색
    borderRadius: BorderRadius.circular(12),
  ),
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
)

// 완료 상태 카드
Container(
  decoration: BoxDecoration(
    color: Color(0xFFF0FDF4),   // 연한 초록색
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Color(0xFF7ED321).withOpacity(0.3)),
  ),
)
```

### 7.3 입력 필드

```dart
InputDecoration(
  filled: true,
  fillColor: Color(0xFFF8F9FA),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: Color(0xFFE8ECF0)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: Color(0xFF4A90E2), width: 2),
  ),
  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  hintStyle: TextStyle(
    color: Color(0xFF95A5A6),
    fontSize: 16,
  ),
)
```

---

## 8. 브랜드 보이스 예시

### 8.1 격려 메시지 (DO / DON'T)

```
✅ DO:
"3일 연속! 정말 잘하고 계세요. 하나님께서 기뻐하실 거예요 ✨"
"오랜만이에요. 언제든 돌아오면 돼요 😊"
"오늘도 수고하셨어요. 작은 한 걸음이 큰 변화를 만들어요"
"처음 시작하셨군요! 함께 걸어가요 🌱"

❌ DON'T:
"14일이나 안 하셨네요. 왜 그러셨어요?"
"실패! 다시 시도하세요."
"완료율이 낮습니다. 더 열심히 하세요."
"챌린지 실패! 배지를 잃었습니다."
```

### 8.2 알림 메시지

```
아침 알림:
✅ "☀️ 김성실 집사님, 오늘의 말씀 묵상 준비됐어요"
❌ "알림: 말씀 묵상을 완료하세요"

저녁 알림:
✅ "🌙 오늘 하루 수고하셨어요. 말씀으로 마무리해봐요"
❌ "경고: 오늘 묵상을 완료하지 않으셨습니다"

새 설교:
✅ "📖 이번 주 '하나님의 사랑' 설교가 도착했어요!"
❌ "새 콘텐츠가 업로드되었습니다"
```

### 8.3 오류 메시지

```
네트워크 오류:
✅ "잠깐, 인터넷 연결을 확인해주세요. 다시 시도해볼게요."
❌ "에러: 네트워크 연결 실패 (ERR_NETWORK_CHANGED)"

로그인 실패:
✅ "로그인 정보가 맞지 않아요. 다시 한번 확인해주세요."
❌ "Authentication Failed"

업로드 실패:
✅ "파일 업로드 중 문제가 생겼어요. 잠시 후 다시 시도해주세요."
❌ "Upload Error 500: Internal Server Error"
```

---

## 9. 마케팅 자료 스타일

### 9.1 앱스토어 스크린샷 스타일

```
스크린샷 구성 (6장):
1. 설교 묵상 메인 화면 + 헤드라인
2. AI 격려 시스템
3. 주간 묵상 가이드
4. 목사 대시보드
5. 나의 성장 기록
6. 간증/기도 커뮤니티 (Phase 2)

헤드라인 스타일:
- 폰트: Pretendard Bold
- 크기: 40-48pt
- 색상: Trust Blue 또는 흰색 (배경 따라)
- 배경: 그라데이션 또는 단색

예시 헤드라인:
"설교가 월요일에도 살아있어요"
"5분으로 한 주 말씀 묵상"
"AI가 함께하는 신앙 성장"
```

### 9.2 SNS 콘텐츠 스타일

```
인스타그램 피드:
- 크기: 1080×1080px (정사각형)
- 스타일: 깔끔한 카드 형식
- 컬러: 브랜드 컬러 일관성
- 텍스트: 최소화, 이미지 중심

인스타그램 스토리:
- 크기: 1080×1920px
- 스타일: 앱 화면 목업
- 사용법 튜토리얼

유튜브 썸네일:
- 크기: 1280×720px
- 목사/성도 얼굴 사진 포함
- 큰 텍스트 (시청자 60대 고려)
- 밝은 배경
```

---

## 10. 브랜드 체크리스트

### 신규 디자인 검토 시 확인 사항

```
색상:
□ 브랜드 컬러 팔레트 사용 여부
□ 색상 대비 비율 (WCAG AA: 4.5:1)
□ 색상만으로 정보 전달하지 않음

타이포그래피:
□ Pretendard 폰트 사용
□ 최소 폰트 크기 16pt (본문 18pt)
□ 충분한 행간 (1.5 이상)

버튼/인터랙션:
□ 최소 터치 영역 44×44pt
□ 버튼 높이 48px 이상
□ 주요 CTA 버튼 56px

보이스:
□ 따뜻하고 격려적인 톤
□ 존댓말 사용
□ 이모지 1-2개만
□ 부정적 언어 사용 안 함

접근성:
□ 고대비 모드 지원
□ 폰트 크기 조절 지원
□ 스크린 리더 라벨 추가
```
