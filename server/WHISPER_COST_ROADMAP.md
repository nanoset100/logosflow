# Whisper 비용 절감 로드맵

> 작성일: 2026-05-07 | 기준: 교회 3,000개, 교회당 설교 1회/주

## 비용 시뮬레이션 (OpenAI Whisper 기준: $0.006/분)

| 규모 | 주간 교회 수 | 월 비용 |
|------|-------------|---------|
| 소규모 | 100개/주 | $108/월 |
| 중규모 | 500개/주 | $540/월 |
| 대규모 | 3,000개/주 | $3,240/월 |

> 캐싱 불가 구조: 교회마다 고유한 설교를 1회만 변환 → 모든 요청이 신규 요청

---

## 단계별 전략 로드맵

| 단계 | 교회 수 | 전략 | 월 예상 비용 |
|------|---------|------|-------------|
| **Phase 1 (현재)** | 1~30개 | Groq Whisper API 무료 사용 | $0 |
| **Phase 2 (성장기)** | 30~200개 | Groq 계속 사용 (무료 한도 내) | $0~5 |
| **Phase 3 (확장기)** | 200개+ | Railway Pro + faster-whisper medium | $20~40 |
| **Phase 4 (대규모)** | 1,000개+ | Railway Pro + 멀티 워커 + 큐 시스템 | $50~100 |

---

## Phase 1: Groq Whisper API (현재 적용)

### 왜 Groq인가?
- OpenAI Whisper와 **100% 동일한 API 형식** (코드 변경 최소)
- `whisper-large-v3-turbo` 모델 — OpenAI `whisper-1`보다 **정확도 높음**
- 속도: OpenAI 대비 **5~10배 빠름**
- 비용: **무료** (무료 티어 한도 내)

### Groq 무료 티어 한도
- 분당: 20건
- 일일: 7,200건 / 2,000분
- 30개 교회 주 1회 = 주 30건 → 무료 한도의 **0.4%**

### 변경 범위
- `/transcribe` 엔드포인트만 Groq 사용
- `/ai/tts` (TTS): Groq 미지원 → OpenAI 유지
- `/ai/analyze` (GPT-4o-mini): OpenAI 유지

---

## Phase 3: faster-whisper 자체 호스팅 (200개+ 교회)

### Railway 플랜별 모델 선택
| 플랜 | 메모리 | 모델 | 한국어 정확도 | 월 비용 |
|------|--------|------|-------------|---------|
| Hobby | 512MB | tiny만 가능 | 65~70% (부적합) | $5 |
| Pro | 8GB | **medium (권장)** | 93~95% | $20~ |
| Pro | 16GB | large-v3 | 95~97% | $40~ |

### 비용 손익분기점
```
Railway Pro 추가 비용: ~$25/월
OpenAI Whisper 절감 기준: 25 ÷ (0.006 × 45분 × 4주) ≈ 23개 교회
→ 23개 교회 이상이면 자체 호스팅이 경제적
```

---

## 전체 API 구조 요약

```
Flutter 앱
    │
    ├─ /transcribe          → [Groq] whisper-large-v3-turbo  (무료)
    ├─ /transcribe/youtube  → [Groq] whisper-large-v3-turbo  (무료)
    ├─ /ai/tts              → [OpenAI] tts-1                 (유료 유지)
    └─ /ai/analyze          → [OpenAI] gpt-4o-mini           (유료 유지)
```
