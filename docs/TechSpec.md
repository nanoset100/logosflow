# TechSpec: AI 말씀비서
## 기술 사양서 v1.0

---

## 1. 시스템 아키텍처 개요

```
┌─────────────────────────────────────────────────────┐
│                   클라이언트 레이어                   │
│                                                     │
│  ┌──────────────┐          ┌──────────────────┐    │
│  │  Flutter App  │          │   Pastor Web App  │    │
│  │  (iOS/Android)│          │   (React/Next.js) │    │
│  └──────┬───────┘          └────────┬─────────┘    │
└─────────┼────────────────────────── ┼ ─────────────┘
          │ HTTPS/WSS                 │ HTTPS
┌─────────┼───────────────────────────┼─────────────┐
│         │      Firebase 레이어       │             │
│  ┌──────▼───────────────────────────▼──────┐      │
│  │              Firebase SDK               │      │
│  └──────────────────┬──────────────────────┘      │
│                     │                             │
│  ┌──────────────────▼──────────────────────┐      │
│  │           Firebase Services             │      │
│  │  Auth │ Firestore │ Storage │ FCM │ CF  │      │
│  └──────────────────┬──────────────────────┘      │
└─────────────────────┼───────────────────────────── ┘
                      │
┌─────────────────────▼───────────────────────────── ┐
│                   AI 레이어                         │
│                                                     │
│  Phase 1: Pastors.ai API                            │
│  Phase 2: OpenAI (Whisper + GPT-4)                  │
└─────────────────────────────────────────────────── ┘
```

---

## 2. 프론트엔드 (Flutter)

### 2.1 프레임워크 및 버전

```yaml
# pubspec.yaml
name: chimshin_bible_note
description: AI 말씀비서 - 침신 말씀노트

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.10.0'

dependencies:
  flutter:
    sdk: flutter

  # 상태 관리
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.2.0

  # Firebase
  firebase_core: ^2.24.0
  firebase_auth: ^4.15.0
  cloud_firestore: ^4.13.0
  firebase_storage: ^11.5.0
  firebase_messaging: ^14.7.0
  firebase_analytics: ^10.7.0

  # 소셜 로그인
  google_sign_in: ^6.2.0
  kakao_flutter_sdk: ^1.7.0

  # UI
  go_router: ^12.1.0
  flutter_local_notifications: ^16.3.0
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0

  # 오디오
  just_audio: ^0.9.36
  audio_service: ^0.18.12

  # 유틸리티
  intl: ^0.18.0
  shared_preferences: ^2.2.2
  connectivity_plus: ^5.0.2
  package_info_plus: ^5.0.1
  url_launcher: ^6.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  riverpod_generator: ^2.3.0
  build_runner: ^2.4.6
  flutter_lints: ^3.0.0
  mockito: ^5.4.3
```

### 2.2 프로젝트 구조

```
lib/
├── main.dart
├── app.dart                    # MaterialApp + GoRouter 설정
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart     # 색상 상수
│   │   ├── app_strings.dart    # 텍스트 상수
│   │   └── app_sizes.dart      # 사이즈 상수
│   │
│   ├── theme/
│   │   ├── app_theme.dart      # 전체 테마
│   │   └── text_styles.dart    # 텍스트 스타일
│   │
│   ├── router/
│   │   └── app_router.dart     # GoRouter 설정
│   │
│   └── utils/
│       ├── date_utils.dart
│       └── string_utils.dart
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_repository.dart
│   │   ├── domain/
│   │   │   └── user_model.dart
│   │   └── presentation/
│   │       ├── login_screen.dart
│   │       ├── church_code_screen.dart
│   │       └── onboarding_screen.dart
│   │
│   ├── home/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       └── home_screen.dart
│   │
│   ├── sermon/
│   │   ├── data/
│   │   │   └── sermon_repository.dart
│   │   ├── domain/
│   │   │   ├── sermon_model.dart
│   │   │   └── devotion_model.dart
│   │   └── presentation/
│   │       ├── sermon_list_screen.dart
│   │       └── sermon_detail_screen.dart
│   │
│   ├── devotion/
│   │   ├── data/
│   │   │   └── devotion_repository.dart
│   │   ├── domain/
│   │   │   └── progress_model.dart
│   │   └── presentation/
│   │       ├── daily_devotion_screen.dart
│   │       └── completion_screen.dart
│   │
│   ├── record/
│   │   └── presentation/
│   │       └── my_record_screen.dart
│   │
│   ├── community/              # Phase 2
│   │   ├── testimony/
│   │   └── prayer/
│   │
│   └── pastor/
│       ├── data/
│       │   └── pastor_repository.dart
│       └── presentation/
│           ├── pastor_dashboard_screen.dart
│           └── sermon_upload_screen.dart
│
└── shared/
    ├── widgets/
    │   ├── sermon_card.dart
    │   ├── encouragement_card.dart
    │   ├── progress_indicator.dart
    │   └── loading_overlay.dart
    │
    └── providers/
        ├── auth_provider.dart
        └── church_provider.dart
```

### 2.3 상태 관리 패턴 (Riverpod)

```dart
// features/sermon/data/sermon_repository.dart
@riverpod
class SermonRepository extends _$SermonRepository {
  @override
  FutureOr<List<Sermon>> build() async {
    final churchId = ref.watch(currentChurchIdProvider);
    return _fetchSermons(churchId);
  }

  Future<List<Sermon>> _fetchSermons(String churchId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('churches')
        .doc(churchId)
        .collection('sermons')
        .orderBy('date', descending: true)
        .limit(10)
        .get();

    return snapshot.docs
        .map((doc) => Sermon.fromFirestore(doc))
        .toList();
  }
}

// features/devotion/data/devotion_repository.dart
@riverpod
class DevotionProgress extends _$DevotionProgress {
  @override
  Future<Map<String, bool>> build(String sermonId) async {
    final userId = ref.watch(currentUserIdProvider);
    final churchId = ref.watch(currentChurchIdProvider);
    return _fetchProgress(churchId, userId, sermonId);
  }

  Future<void> completeDay(String sermonId, int day) async {
    final userId = ref.read(currentUserIdProvider);
    final churchId = ref.read(currentChurchIdProvider);

    await FirebaseFirestore.instance
        .collection('churches')
        .doc(churchId)
        .collection('members')
        .doc(userId)
        .collection('progress')
        .doc(sermonId)
        .set({'day${day}_complete': true}, SetOptions(merge: true));

    ref.invalidateSelf();
  }
}
```

### 2.4 라우팅 (GoRouter)

```dart
// core/router/app_router.dart
@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isOnboarding = state.matchedLocation.startsWith('/onboarding');
      final isAuth = state.matchedLocation.startsWith('/auth');

      if (!isLoggedIn && !isOnboarding && !isAuth) {
        return '/auth/login';
      }
      if (isLoggedIn && isAuth) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(
            path: '/sermon/:id',
            builder: (_, state) =>
                SermonDetailScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/devotion/:sermonId/:day',
            builder: (_, state) => DailyDevotionScreen(
              sermonId: state.pathParameters['sermonId']!,
              day: int.parse(state.pathParameters['day']!),
            ),
          ),
          GoRoute(path: '/record', builder: (_, __) => const MyRecordScreen()),
          GoRoute(
            path: '/pastor',
            builder: (_, __) => const PastorDashboardScreen(),
          ),
        ],
      ),
    ],
  );
}
```

---

## 3. 백엔드 (Firebase)

### 3.1 Firestore 데이터 모델

```typescript
// Firestore 스키마 (TypeScript 타입 정의)

interface Church {
  id: string;
  name: string;
  pastor: string;
  denomination: 'baptist' | 'presbyterian' | 'methodist' | 'holiness' | 'other';
  plan: 'chimshin' | 'wordbridge';
  memberCount: number;
  churchCode: string;         // 4자리 코드
  logoUrl?: string;
  primaryColor?: string;      // 화이트라벨용
  settings: ChurchSettings;
  createdAt: Timestamp;
  subscriptionStatus: 'trial' | 'active' | 'expired';
  subscriptionEndDate: Timestamp;
}

interface ChurchSettings {
  autoApproveMembers: boolean;
  notificationSchedule: NotificationSchedule;
  testimonyCuration: 'auto' | 'manual'; // 간증 자동/수동 게시
}

interface NotificationSchedule {
  morning: string;   // "09:00"
  lunch: boolean;
  evening: string;   // "20:00"
}

interface Sermon {
  id: string;
  churchId: string;
  title: string;
  date: Timestamp;
  pastor: string;
  bibleBook: string;         // "요한복음"
  bibleChapter: number;      // 3
  bibleVerseStart: number;   // 16
  bibleVerseEnd?: number;    // 17
  audioUrl?: string;
  youtubeUrl?: string;
  transcriptText?: string;   // STT 결과 또는 원고
  summary: string;           // AI 생성 요약 (300자)
  keyTakeaways: string[];    // 핵심 포인트 3개
  devotional: DailyDevotion[];  // 5일치
  aiProcessingStatus: 'pending' | 'processing' | 'complete' | 'failed';
  aiProcessingCompletedAt?: Timestamp;
  createdAt: Timestamp;
  publishedAt?: Timestamp;
}

interface DailyDevotion {
  day: number;               // 1-5
  theme: string;             // "깨달음의 날"
  bibleVerse: string;        // 구절
  bibleText: string;         // 본문
  meditation: string;        // 묵상 가이드
  question: string;          // 묵상 질문
  application: string;       // 적용 방법
}

interface Member {
  id: string;
  churchId: string;
  uid: string;               // Firebase Auth UID
  name: string;
  phone?: string;
  email?: string;
  ageGroup: '20s' | '30s' | '40s' | '50s' | '60s+';
  role: 'member' | 'deacon' | 'elder' | 'pastor' | 'admin';
  notificationSettings: NotificationSchedule;
  joinedAt: Timestamp;
  lastActiveAt: Timestamp;
  isActive: boolean;
}

interface MemberProgress {
  memberId: string;
  sermonId: string;
  day1Complete: boolean;
  day2Complete: boolean;
  day3Complete: boolean;
  day4Complete: boolean;
  day5Complete: boolean;
  day1Note?: string;
  day2Note?: string;
  day3Note?: string;
  day4Note?: string;
  day5Note?: string;
  day1CompletedAt?: Timestamp;
  day5CompletedAt?: Timestamp;
}

interface Testimony {
  id: string;
  memberId: string;
  memberName: string;         // 비정규화
  churchId: string;
  sermonId?: string;
  title?: string;
  content: string;
  visibility: 'church' | 'public' | 'pastor_only';
  status: 'pending' | 'approved' | 'rejected';
  likeCount: number;
  commentCount: number;
  createdAt: Timestamp;
  approvedAt?: Timestamp;
}

interface Prayer {
  id: string;
  memberId: string;
  memberName: string;
  churchId: string;
  content: string;
  type: 'urgent' | 'ongoing';
  prayerCount: number;
  isAnswered: boolean;
  visibility: 'personal' | 'group' | 'church';
  expiresAt?: Timestamp;
  createdAt: Timestamp;
}
```

### 3.2 Firestore Security Rules

```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // 공통 함수
    function isAuthenticated() {
      return request.auth != null;
    }

    function isChurchMember(churchId) {
      return isAuthenticated() &&
        exists(/databases/$(database)/documents/churches/$(churchId)/members/$(request.auth.uid));
    }

    function isPastor(churchId) {
      return isAuthenticated() &&
        get(/databases/$(database)/documents/churches/$(churchId)/members/$(request.auth.uid)).data.role == 'pastor';
    }

    function isAdmin(churchId) {
      return isAuthenticated() &&
        get(/databases/$(database)/documents/churches/$(churchId)/members/$(request.auth.uid)).data.role in ['pastor', 'admin'];
    }

    // 교회 정보: 교인만 읽기, 관리자만 쓰기
    match /churches/{churchId} {
      allow read: if isChurchMember(churchId);
      allow write: if isAdmin(churchId);

      // 설교: 교인 읽기, 관리자 쓰기
      match /sermons/{sermonId} {
        allow read: if isChurchMember(churchId);
        allow write: if isAdmin(churchId);
      }

      // 교인: 본인만 읽기/쓰기, 목사는 전체 읽기
      match /members/{memberId} {
        allow read: if request.auth.uid == memberId || isPastor(churchId);
        allow write: if request.auth.uid == memberId || isAdmin(churchId);

        // 개인 진행 현황: 본인만 읽기/쓰기
        match /progress/{sermonId} {
          allow read, write: if request.auth.uid == memberId;
          // 목사는 집계 통계만 (개별 묵상 메모 접근 불가)
        }
      }

      // 간증: 교인 읽기, 본인 쓰기, 목사 승인
      match /testimonies/{testimonyId} {
        allow read: if isChurchMember(churchId) &&
          (resource.data.status == 'approved' ||
           resource.data.memberId == request.auth.uid ||
           isPastor(churchId));
        allow create: if isChurchMember(churchId);
        allow update: if resource.data.memberId == request.auth.uid ||
          isPastor(churchId);
        allow delete: if resource.data.memberId == request.auth.uid ||
          isAdmin(churchId);
      }

      // 기도 제목
      match /prayers/{prayerId} {
        allow read: if isChurchMember(churchId) &&
          (resource.data.visibility != 'personal' ||
           resource.data.memberId == request.auth.uid);
        allow create, update, delete: if isChurchMember(churchId) &&
          resource.data.memberId == request.auth.uid;
      }
    }
  }
}
```

### 3.3 Cloud Functions

```typescript
// functions/src/index.ts

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { processSermonWithAI } from './ai/sermon-processor';
import { sendPushNotification } from './notifications/push';
import { generateEncouragement } from './ai/encouragement';

admin.initializeApp();

// 설교 업로드 시 AI 처리 트리거
export const onSermonCreated = functions
  .region('asia-northeast3') // 서울
  .firestore
  .document('churches/{churchId}/sermons/{sermonId}')
  .onCreate(async (snap, context) => {
    const sermon = snap.data();
    const { churchId, sermonId } = context.params;

    // AI 처리 시작
    await snap.ref.update({ aiProcessingStatus: 'processing' });

    try {
      const processedContent = await processSermonWithAI({
        audioUrl: sermon.audioUrl,
        youtubeUrl: sermon.youtubeUrl,
        transcriptText: sermon.transcriptText,
        title: sermon.title,
        bibleReference: `${sermon.bibleBook} ${sermon.bibleChapter}:${sermon.bibleVerseStart}`,
      });

      await snap.ref.update({
        summary: processedContent.summary,
        keyTakeaways: processedContent.keyTakeaways,
        devotional: processedContent.devotional,
        transcriptText: processedContent.transcript,
        aiProcessingStatus: 'complete',
        aiProcessingCompletedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 목사에게 처리 완료 알림
      await sendProcessingCompleteNotification(churchId, sermon.title);

    } catch (error) {
      await snap.ref.update({ aiProcessingStatus: 'failed' });
      console.error('AI processing failed:', error);
    }
  });

// 일일 묵상 완료 시 격려 메시지 생성
export const onDevotionComplete = functions
  .region('asia-northeast3')
  .firestore
  .document('churches/{churchId}/members/{memberId}/progress/{sermonId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const { churchId, memberId } = context.params;

    // 새로 완료된 날 감지
    for (let day = 1; day <= 5; day++) {
      if (!before[`day${day}Complete`] && after[`day${day}Complete`]) {
        const streak = await calculateStreak(churchId, memberId);
        const message = generateEncouragement({
          day,
          streak,
          isFirstTime: streak === 1,
        });

        // 인앱 알림 전송
        await sendInAppNotification(churchId, memberId, message);
        break;
      }
    }
  });

// 매일 아침 9시 푸시 알림 (KST)
export const dailyMorningNotification = functions
  .region('asia-northeast3')
  .pubsub
  .schedule('0 0 * * *')  // UTC 00:00 = KST 09:00
  .timeZone('Asia/Seoul')
  .onRun(async () => {
    const churches = await admin.firestore()
      .collection('churches')
      .where('subscriptionStatus', '==', 'active')
      .get();

    for (const church of churches.docs) {
      await sendDailyNotificationToChurch(church.id);
    }
  });

// 목사 주간 리포트 (매주 월요일 오전 9시)
export const weeklyPastorReport = functions
  .region('asia-northeast3')
  .pubsub
  .schedule('0 0 * * 1')  // 매주 월요일 UTC 00:00
  .timeZone('Asia/Seoul')
  .onRun(async () => {
    const churches = await admin.firestore()
      .collection('churches')
      .where('subscriptionStatus', '==', 'active')
      .get();

    for (const church of churches.docs) {
      const report = await generateWeeklyReport(church.id);
      await sendReportToPastor(church.id, report);
    }
  });
```

### 3.4 AI 처리 모듈

```typescript
// functions/src/ai/sermon-processor.ts

import OpenAI from 'openai';
import axios from 'axios';

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

interface SermonInput {
  audioUrl?: string;
  youtubeUrl?: string;
  transcriptText?: string;
  title: string;
  bibleReference: string;
}

interface ProcessedSermon {
  transcript: string;
  summary: string;
  keyTakeaways: string[];
  devotional: DailyDevotion[];
}

export async function processSermonWithAI(input: SermonInput): Promise<ProcessedSermon> {

  // 1단계: 텍스트 확보
  let transcript = input.transcriptText;
  if (!transcript && input.audioUrl) {
    transcript = await transcribeAudio(input.audioUrl);
  }
  if (!transcript && input.youtubeUrl) {
    transcript = await transcribeYoutube(input.youtubeUrl);
  }

  // 2단계: GPT-4로 콘텐츠 생성
  const content = await generateContent(transcript!, input.title, input.bibleReference);

  return { transcript: transcript!, ...content };
}

async function transcribeAudio(audioUrl: string): Promise<string> {
  // Whisper API 사용
  const audioResponse = await axios.get(audioUrl, { responseType: 'arraybuffer' });
  const audioBuffer = Buffer.from(audioResponse.data);

  const formData = new FormData();
  formData.append('file', new Blob([audioBuffer]), 'sermon.mp3');
  formData.append('model', 'whisper-1');
  formData.append('language', 'ko');

  const transcription = await openai.audio.transcriptions.create({
    file: new File([audioBuffer], 'sermon.mp3', { type: 'audio/mp3' }),
    model: 'whisper-1',
    language: 'ko',
  });

  return transcription.text;
}

async function generateContent(
  transcript: string,
  title: string,
  bibleRef: string
): Promise<Omit<ProcessedSermon, 'transcript'>> {

  const prompt = `
당신은 한국 침례교 신학자입니다. 아래 설교를 분석하여 성도들의 일주일 묵상 가이드를 만들어주세요.

설교 제목: ${title}
본문 말씀: ${bibleRef}
설교 내용:
${transcript.substring(0, 8000)}

다음 형식으로 JSON 응답하세요:
{
  "summary": "설교 요약 (300자 이내, 핵심 메시지 중심)",
  "keyTakeaways": ["핵심 포인트 1", "핵심 포인트 2", "핵심 포인트 3"],
  "devotional": [
    {
      "day": 1,
      "theme": "깨달음의 날",
      "bibleVerse": "성경 구절 (설교 본문 중)",
      "bibleText": "구절 전문",
      "meditation": "묵상 가이드 (100자)",
      "question": "묵상 질문 (어른 친화적, 구체적)",
      "application": "오늘 적용할 수 있는 구체적 방법 (50자)"
    },
    // day 2: 계획의 날
    // day 3: 점검의 날
    // day 4: 심화의 날
    // day 5: 정리의 날
  ]
}

작성 원칙:
- 50-70대 성도도 이해하기 쉬운 언어 사용
- 지나치게 신학적인 용어 피하기
- 따뜻하고 격려적인 톤
- 실생활에서 바로 적용 가능한 내용
- 존댓말 사용 (~하세요, ~해보세요)
`;

  const response = await openai.chat.completions.create({
    model: 'gpt-4-turbo-preview',
    messages: [{ role: 'user', content: prompt }],
    response_format: { type: 'json_object' },
    temperature: 0.7,
  });

  return JSON.parse(response.choices[0].message.content!);
}
```

---

## 4. 푸시 알림 시스템

### 4.1 FCM 설정

```typescript
// functions/src/notifications/push.ts

import * as admin from 'firebase-admin';

interface NotificationPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
  imageUrl?: string;
}

export async function sendPushToMember(
  memberId: string,
  churchId: string,
  payload: NotificationPayload
): Promise<void> {
  const memberDoc = await admin.firestore()
    .collection('churches').doc(churchId)
    .collection('members').doc(memberId)
    .get();

  const member = memberDoc.data();
  if (!member?.fcmTokens?.length) return;

  const messages = member.fcmTokens.map((token: string) => ({
    token,
    notification: {
      title: payload.title,
      body: payload.body,
      imageUrl: payload.imageUrl,
    },
    data: payload.data || {},
    android: {
      priority: 'high' as const,
      notification: {
        channelId: 'devotion_reminder',
        priority: 'high' as const,
        sound: 'default',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          badge: 1,
        },
      },
    },
  }));

  await admin.messaging().sendEach(messages);
}
```

### 4.2 알림 유형 및 메시지 템플릿

```typescript
// functions/src/notifications/templates.ts

export const NOTIFICATION_TEMPLATES = {
  MORNING: (name: string, sermonTitle: string) => ({
    title: `🌅 오늘의 말씀`,
    body: `${name}님, "${sermonTitle}" 묵상 준비됐어요`,
    data: { screen: 'home', action: 'open_devotion' },
  }),

  SERMON_READY: (title: string) => ({
    title: `📖 이번 주 말씀 도착!`,
    body: `"${title}" 설교가 등록됐어요`,
    data: { screen: 'sermon_list' },
  }),

  STREAK_3: (name: string) => ({
    title: `🔥 3일 연속!`,
    body: `${name}님, 정말 잘하고 계세요!`,
    data: { screen: 'record' },
  }),

  RETURN_AFTER_SKIP: (name: string) => ({
    title: `💝 다시 시작해요`,
    body: `${name}님, 기다리고 있었어요`,
    data: { screen: 'home' },
  }),

  PASTOR_REPORT: (churchName: string) => ({
    title: `📊 주간 리포트`,
    body: `${churchName} 이번 주 참여 현황을 확인하세요`,
    data: { screen: 'pastor_dashboard' },
  }),
};
```

---

## 5. 보안 설계

### 5.1 인증 아키텍처

```
사용자 인증 플로우:

소셜 로그인 (카카오/구글)
        ↓
Firebase Auth (JWT 토큰 발급)
        ↓
교회 멤버십 확인 (Firestore)
        ↓
역할 기반 접근 제어 (RBAC)
        ↓
Firestore Security Rules 적용

토큰 관리:
- ID Token: 1시간 유효
- Refresh Token: 자동 갱신
- 앱 세션: 30일 유지
- 장기 미사용 시 재로그인 (180일)
```

### 5.2 데이터 보호

```typescript
// 민감한 데이터 처리 원칙

// 1. 개인 묵상 메모 - 암호화 저장
class EncryptedNoteStorage {
  private readonly KEY_PREFIX = 'member_note_';

  async saveNote(memberId: string, content: string): Promise<void> {
    // AES-256 암호화 후 저장
    const encrypted = await this.encrypt(content, memberId);
    await FirebaseFirestore.instance
      .collection('encrypted_notes')
      .doc(`${memberId}_${Date.now()}`)
      .set({ data: encrypted });
  }

  // 목사도 개별 메모 열람 불가 (암호화 키: 사용자별)
}

// 2. 집계 통계만 목사에게 제공
interface PastorStats {
  totalMembers: number;
  activeThisWeek: number;
  completionRate: number;
  averageStreak: number;
  // ❌ 개별 사용자 메모 없음
  // ❌ 개인 기도 제목 없음
}
```

### 5.3 교회 간 데이터 격리

```javascript
// Firestore 구조상 교회 단위 격리
// 모든 데이터는 /churches/{churchId}/ 하위

// Cloud Function에서 churchId 검증
export const getChurchStats = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) throw new Error('Unauthorized');

    const { churchId } = data;

    // 요청자가 해당 교회 멤버인지 확인
    const memberDoc = await admin.firestore()
      .collection('churches').doc(churchId)
      .collection('members').doc(context.auth.uid)
      .get();

    if (!memberDoc.exists) {
      throw new functions.https.HttpsError('permission-denied', '접근 권한이 없습니다');
    }

    // 통계 반환
    return await calculateChurchStats(churchId);
  }
);
```

---

## 6. 성능 최적화

### 6.1 Flutter 성능

```dart
// 리스트 최적화 - ListView.builder 사용
ListView.builder(
  itemCount: sermons.length,
  itemExtent: 120,  // 고정 높이로 성능 향상
  itemBuilder: (context, index) {
    return SermonCard(sermon: sermons[index]);
  },
);

// 이미지 캐싱
CachedNetworkImage(
  imageUrl: sermon.thumbnailUrl ?? '',
  placeholder: (_, __) => const ShimmerBox(),
  errorWidget: (_, __, ___) => const DefaultThumbnail(),
  memCacheWidth: 300,  // 메모리 최적화
);

// 상태 구독 최적화 - select로 필요한 부분만
final completionRate = ref.watch(
  progressProvider(sermonId).select(
    (p) => p.value?.completionRate ?? 0.0,
  ),
);
```

### 6.2 Firestore 쿼리 최적화

```typescript
// 인덱스 설정 (firestore.indexes.json)
{
  "indexes": [
    {
      "collectionGroup": "sermons",
      "fields": [
        { "fieldPath": "date", "order": "DESCENDING" },
        { "fieldPath": "publishedAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "testimonies",
      "fields": [
        { "fieldPath": "churchId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ]
}

// 페이지네이션으로 대량 데이터 처리
async function getPaginatedSermons(
  churchId: string,
  lastDoc?: DocumentSnapshot,
  pageSize = 10
) {
  let query = db.collection('churches').doc(churchId)
    .collection('sermons')
    .orderBy('date', 'desc')
    .limit(pageSize);

  if (lastDoc) {
    query = query.startAfter(lastDoc);
  }

  return query.get();
}
```

---

## 7. 테스트 전략

### 7.1 단위 테스트

```dart
// test/features/devotion/devotion_repository_test.dart
void main() {
  group('DevotionRepository', () {
    late MockFirestore mockFirestore;
    late DevotionRepository repository;

    setUp(() {
      mockFirestore = MockFirestore();
      repository = DevotionRepository(firestore: mockFirestore);
    });

    test('completeDay updates Firestore correctly', () async {
      // Arrange
      const churchId = 'church_123';
      const memberId = 'member_456';
      const sermonId = 'sermon_789';
      const day = 3;

      // Act
      await repository.completeDay(
        churchId: churchId,
        memberId: memberId,
        sermonId: sermonId,
        day: day,
      );

      // Assert
      verify(mockFirestore
        .collection('churches')
        .doc(churchId)
        .collection('members')
        .doc(memberId)
        .collection('progress')
        .doc(sermonId)
        .set({'day3_complete': true}, SetOptions(merge: true))
      ).called(1);
    });
  });
}
```

### 7.2 통합 테스트

```dart
// integration_test/app_test.dart
void main() {
  group('User Journey: Daily Devotion', () {
    testWidgets('complete daily devotion flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 홈 화면 확인
      expect(find.text('오늘의 말씀'), findsOneWidget);

      // 묵상 시작
      await tester.tap(find.text('오늘 묵상 시작'));
      await tester.pumpAndSettle();

      // 묵상 화면 확인
      expect(find.byType(DailyDevotionScreen), findsOneWidget);

      // 완료 탭
      await tester.tap(find.text('오늘 완료!'));
      await tester.pumpAndSettle();

      // 완료 화면 확인
      expect(find.byType(CompletionScreen), findsOneWidget);
      expect(find.text('완료!'), findsOneWidget);
    });
  });
}
```

---

## 8. 모니터링 및 운영

### 8.1 Firebase Analytics 이벤트

```dart
// core/analytics/analytics_service.dart
class AnalyticsService {
  final FirebaseAnalytics _analytics;

  Future<void> logDevotionComplete({
    required String sermonId,
    required int day,
    required bool hasNote,
  }) async {
    await _analytics.logEvent(
      name: 'devotion_complete',
      parameters: {
        'sermon_id': sermonId,
        'day': day,
        'has_note': hasNote,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  Future<void> logEncouragementShown({
    required String type,
    required int streak,
  }) async {
    await _analytics.logEvent(
      name: 'encouragement_shown',
      parameters: {'type': type, 'streak': streak},
    );
  }
}
```

### 8.2 Crashlytics 설정

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(
    ProviderScope(
      child: const App(),
    ),
  );
}
```

### 8.3 SLA 및 모니터링 지표

| 지표 | 목표 | 알림 임계값 |
|------|------|------------|
| 앱 크래시율 | < 0.5% | > 1% |
| Firestore 지연 | < 500ms | > 2000ms |
| AI 처리 시간 | < 30분 | > 60분 |
| FCM 전달률 | > 95% | < 90% |
| 월간 가용성 | > 99.5% | < 99% |

---

## 9. 배포 전략

### 9.1 CI/CD 파이프라인

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - run: flutter test
      - run: flutter analyze

  deploy-android:
    needs: test
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build Android
        run: flutter build appbundle --release
      - name: Deploy to Play Store
        uses: r0adkll/upload-google-play@v1

  deploy-ios:
    needs: test
    if: github.ref == 'refs/heads/main'
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build iOS
        run: flutter build ipa --release
      - name: Deploy to App Store
        uses: apple-actions/upload-testflight-build@v1
```

### 9.2 환경 분리

```
환경:
- development: 로컬 개발 + Firebase Emulator
- staging: 파일럿 교회 테스트 (Firebase Staging Project)
- production: 실 서비스 (Firebase Production Project)

환경변수 관리:
- .env.development
- .env.staging
- .env.production
- GitHub Secrets으로 CI/CD 관리
```
