# Logosflow YouTube 오디오 추출 실패 디버그 리포트

**작성일**: 2026-04-01
**작성자**: Claude Opus 4.6 + 사용자 공동 작업
**상태**: ❌ 미해결 — 쿠키 문제로 추정

---

## 1. 문제 요약

침신앱/wordbridge 앱에서 YouTube 설교 영상 URL을 입력하고 "AI 자동 생성" 버튼을 누르면:

```
YouTube 오디오 추출 실패: WARNING: [youtube] No title found in player responses;
falling back to title from initial data. Other metadata may also be missing
ERROR: [youtube] TO__5AoKtZ4: Sign in to confirm you're not a bot.
Use --cookies-from-browser or --cookies for the authentication.
```

**영상 ID**: `TO__5AoKtZ4` (사도행전 20장 설교)

---

## 2. 근본 원인 분석

YouTube가 Railway 클라우드 IP를 봇으로 인식하여 로그인을 요구함.
3가지 요인이 결합:

| 원인 | 설명 | 해결 여부 |
|------|------|-----------|
| Node.js 미설치 | yt-dlp가 YouTube JS 챌린지를 풀 수 없음 | ✅ 해결 |
| JS 런타임 미지정 | `--js-runtimes` 플래그 누락 | ✅ 해결 |
| 봇 감지 (429) | 클라우드 IP → YouTube가 쿠키/로그인 요구 | ❌ 미해결 |

---

## 3. 수행한 작업 (시간순)

### 3-1. 이전 작업 (Antigravity AI, 6회 시도 실패)
- yt-dlp 버전 업데이트
- `YOUTUBE_COOKIES` 환경변수 설정 (Railway)
- 다양한 yt-dlp 옵션 시도
- **결과**: 모두 실패

### 3-2. Claude 작업 (2026-04-01)

#### Step 1: Dockerfile에 Node.js 추가
```dockerfile
# 변경 전
RUN apt-get update && apt-get install -y --no-install-recommends ffmpeg

# 변경 후
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    nodejs \
    && rm -rf /var/lib/apt/lists/*
```
**이유**: yt-dlp가 YouTube JS 챌린지를 해석하려면 JavaScript 런타임 필요

#### Step 2: yt-dlp 명령에 `--js-runtimes node` 추가
```python
cmd = [
    "yt-dlp", "-x", "--audio-format", "mp3",
    "--audio-quality", "64K", "--no-playlist",
    "--js-runtimes", "node",        # ← 추가
    "--sleep-requests", "1",         # ← 추가 (요청 간 딜레이)
    "--min-sleep-interval", "1",     # ← 추가
    "--max-sleep-interval", "3",     # ← 추가
    "-o", output_path + ".%(ext)s",
]
```
**주의**: `--js-runtimes nodejs`는 오류 발생. 올바른 값은 `node`
- 지원 런타임: `deno`, `node`, `bun`, `quickjs`

#### Step 3: 쿠키 로직 확인
```python
cookie_file = "/tmp/youtube_cookies.txt"
cookie_content = os.getenv("YOUTUBE_COOKIES", "")
if cookie_content:
    with open(cookie_file, "w", encoding="utf-8") as f:
        f.write(cookie_content)
# ...
if cookie_content and Path(cookie_file).exists():
    cmd += ["--cookies", cookie_file]
```
- `YOUTUBE_COOKIES` 환경변수는 Railway에 설정 확인 완료

---

## 4. 테스트 결과

| 테스트 | 방법 | 결과 |
|--------|------|------|
| curl API 직접 호출 | 공개 YouTube 영상 | ✅ HTTP 200, 전사 성공 |
| 앱에서 설교 영상 | TO__5AoKtZ4 | ❌ "Sign in to confirm you're not a bot" |

**curl 성공 명령어**:
```bash
curl -X POST https://logosflow-production.up.railway.app/transcribe/youtube \
  -F "url=https://www.youtube.com/watch?v=<공개영상ID>" \
  -F "language=ko"
```

---

## 5. 미해결 원인 추정

### 가설 A: 쿠키 포맷 문제 (가능성 높음)
- `YOUTUBE_COOKIES` 값이 **Netscape 쿠키 포맷**이어야 함
- 환경변수에 직접 넣으면 줄바꿈(`\n`)이 깨질 수 있음
- Railway 환경변수는 여러 줄 값 저장 시 이스케이프 필요

**Netscape 쿠키 포맷 예시**:
```
# Netscape HTTP Cookie File
.youtube.com	TRUE	/	TRUE	1700000000	LOGIN_INFO	AFmmF2...
.youtube.com	TRUE	/	FALSE	1700000000	SID	abc123...
```

### 가설 B: 쿠키 만료
- 쿠키가 이미 만료되었을 수 있음
- YouTube 쿠키는 보통 수개월~1년 유효하지만 강제 만료 가능

### 가설 C: 특정 영상 제한
- 해당 설교 영상(`TO__5AoKtZ4`)에 특별한 접근 제한이 있을 수 있음
- 비공개는 아니지만 "일부 공개" 또는 연령 제한 등

---

## 6. 다음에 시도할 해결 방법

### 방법 1: 쿠키 재추출 + 포맷 확인 (권장)
1. PC Chrome에서 YouTube 로그인
2. 확장프로그램 "Get cookies.txt LOCALLY" 설치
3. youtube.com에서 쿠키 내보내기 (Netscape format)
4. 파일 내용을 Railway `YOUTUBE_COOKIES`에 붙여넣기
5. **중요**: 줄바꿈이 제대로 들어가는지 확인

### 방법 2: 쿠키를 파일로 배포
```dockerfile
# Dockerfile에 쿠키 파일 복사
COPY cookies.txt /app/cookies.txt
```
```python
# main.py에서 고정 경로 사용
cookie_file = "/app/cookies.txt"
if Path(cookie_file).exists():
    cmd += ["--cookies", cookie_file]
```
- **장점**: 줄바꿈 문제 없음
- **단점**: 쿠키 갱신 시 재배포 필요, 보안 주의 (gitignore 필수)

### 방법 3: 쿠키 환경변수 디코딩 개선
```python
# base64 인코딩으로 줄바꿈 보존
import base64
cookie_content = os.getenv("YOUTUBE_COOKIES", "")
if cookie_content:
    try:
        decoded = base64.b64decode(cookie_content).decode("utf-8")
        with open(cookie_file, "w", encoding="utf-8") as f:
            f.write(decoded)
    except Exception:
        # base64가 아니면 그냥 저장
        with open(cookie_file, "w", encoding="utf-8") as f:
            f.write(cookie_content)
```

### 방법 4: yt-dlp 대안 — oauth2 플러그인
```bash
pip install yt-dlp[default]
yt-dlp --username oauth2 --password '' URL
```
- OAuth2 브라우저 인증 → 토큰 자동 갱신
- 서버 환경에서는 초기 인증이 어려울 수 있음

---

## 7. 현재 배포 상태

- **서비스**: Railway `logosflow` → `logosflow-production.up.railway.app`
- **Dockerfile**: Node.js 포함 ✅
- **yt-dlp 옵션**: `--js-runtimes node` + 딜레이 ✅
- **YOUTUBE_COOKIES**: Railway 환경변수 설정됨 ✅ (포맷/유효성 미확인)
- **최신 배포**: 2026-04-01 완료

---

## 8. 파일 변경 내역

| 파일 | 변경 내용 |
|------|-----------|
| `server/Dockerfile` | `nodejs` 패키지 추가 |
| `server/main.py` (347-404행) | `--js-runtimes node`, 딜레이 옵션 3개 추가 |

---

*이 문서는 내일 작업 재개 시 참고용으로 작성됨*
