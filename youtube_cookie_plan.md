# YouTube 쿠키 인증 도입 작업 계획서

**작성일:** 2026-04-01  
**작성자:** Antigravity  
**목적:** Claude Code 및 제3자 AI 검증 요청

---

## 1. 문제 요약 (확정된 사실)

- **원인:** Railway 서버의 데이터센터 IP가 YouTube에 봇으로 차단됨
- **증상:** `yt-dlp`로 YouTube 오디오 다운로드 시 항상 500 오류
- **시도한 우회책 (모두 실패):** android/web/ios player_client 옵션, User-Agent 변경, no-check-certificates
- **결론:** 2025년 기준 YouTube는 데이터센터 IP + yt-dlp 조합을 완벽히 차단. 쿠키 인증만이 유일한 해결책

---

## 2. 작업 계획 (솔직하게)

### 변경할 파일: `server/main.py` 딱 1개만

**변경 내용:**

```python
# 현재 (실패하는 코드)
cmd = [
    "yt-dlp", "-x", "--audio-format", "mp3",
    "--audio-quality", "64K", "--no-playlist",
    "-o", output_path + ".%(ext)s", url,
]

# 변경 후 (쿠키 인증 추가)
import tempfile as _tf

# Railway 환경변수에서 쿠키 내용 읽기
cookie_content = os.getenv("YOUTUBE_COOKIES", "")
cookie_file_path = None

if cookie_content:
    # 임시 쿠키 파일 생성
    cookie_tmp = _tf.NamedTemporaryFile(
        mode='w', suffix='.txt', delete=False
    )
    cookie_tmp.write(cookie_content)
    cookie_tmp.close()
    cookie_file_path = cookie_tmp.name

cmd = [
    "yt-dlp", "-x", "--audio-format", "mp3",
    "--audio-quality", "64K", "--no-playlist",
    "-o", output_path + ".%(ext)s",
]

if cookie_file_path:
    cmd += ["--cookies", cookie_file_path]

cmd.append(url)

# ... yt-dlp 실행 후 임시 쿠키 파일 삭제
if cookie_file_path:
    Path(cookie_file_path).unlink(missing_ok=True)
```

### 변경하지 않을 파일

- Flutter 앱 코드 전체 (sermon_register_screen.dart, youtube_service.dart 등)
- pubspec.yaml
- Dockerfile
- requirements.txt
- 다른 서버 엔드포인트

---

## 3. 사용자가 직접 해야 할 사항 (AI가 할 수 없는 것)

### Step 1: Chrome 쿠키 추출

1. 크롬 브라우저에서 YouTube에 **로그인**된 상태로
2. 크롬 확장 프로그램 "**Get cookies.txt LOCALLY**" 설치
3. YouTube 접속 후 확장 프로그램 클릭 → **"Export"** 선택
4. `cookies.txt` 파일 다운로드

### Step 2: Railway 환경변수 등록

1. Railway 콘솔 → logosflow → **Variables** 탭
2. **New Variable** 클릭
3. 이름: `YOUTUBE_COOKIES`
4. 값: `cookies.txt` 파일의 **전체 내용을 복사해서 붙여넣기**

### Step 3: 확인 후 GitHub Push 요청

경수님이 계획서 확인 후 승인하시면, 제가 코드 수정 → GitHub Push를 진행합니다.

---

## 4. 솔직한 한계와 주의사항

### ✅ 가능한 것
- 쿠키 인증으로 서버 IP 차단 우회
- YouTube 오디오 다운로드 → Whisper STT → AI 분석 복원
- yt-dlp 명령 딱 1개 파일만 수정

### ❌ 못하는 것 / 한계
1. **쿠키는 영구적이지 않습니다.** YouTube 쿠키는 보통 1~2년마다 만료되거나, YouTube가 비정상적인 접근을 감지하면 무효화될 수 있습니다. 그때마다 쿠키를 다시 추출해서 Railway 환경변수를 업데이트해야 합니다.

2. **YouTube 계정 보안 위험:** 쿠키에는 로그인 토큰이 포함되어 있습니다. Railway 환경변수에 저장하는 것은 비교적 안전하지만, 이 쿠키가 유출되면 해당 YouTube 계정이 위험해질 수 있습니다. **전용 구글 계정(메인 계정 X)을 만들어 사용하는 것을 강력히 권장합니다.**

3. **YouTube 정책에 따라 무효화 가능:** 구글이 이 방법도 막으면 다시 같은 문제가 발생할 수 있습니다. 이 경우 장기적으로는 유료 주거용 프록시나 다른 구조가 필요합니다.

4. **기존 결함 수정 없음:** 오늘 수정했다가 원복한 내용들(sermon_register_screen.dart 등)은 이미 원래 상태로 돌아와 있으므로 추가 작업 불필요합니다.

---

## 5. 오늘 제가 저지른 실수 (재고백)

| 실수 | 결과 |
|------|------|
| 자막 없이 "자막 있을 것"이라고 단정 | 사용자님이 직접 정정 |
| 폰 다운로드 방식 도입 | 40분 설교 → 타임아웃 10분 초과 |
| 근본 원인(쿠키) 먼저 파악 못함 | 6번 시행착오 |
| 여러 파일을 검증 없이 수정 | 코드 복잡도 증가 |

---

**이 계획서를 Claude Code 또는 다른 AI에게 검증 요청해 주세요. 검증 통과 후 말씀해 주시면 작업 시작하겠습니다.**
