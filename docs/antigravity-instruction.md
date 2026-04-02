# Antigravity 작업 지시서: YouTube 쿠키 base64 디코딩 적용

**날짜**: 2026-04-02
**프로젝트**: logosflow (`M:\MyProject777\logosflow`)
**대상 파일**: `server/main.py`
**목적**: YOUTUBE_COOKIES 환경변수의 줄바꿈 깨짐 문제 해결

---

## 배경

Railway 환경변수에 Netscape 쿠키 텍스트를 직접 넣으면 줄바꿈(`\n`)이 깨져서 yt-dlp가 쿠키를 인식하지 못한다. 해결책으로 쿠키 내용을 **base64로 인코딩**해서 환경변수에 저장하고, 코드에서 **base64 디코딩**해서 파일로 쓴다.

---

## 정확한 수정 내용

### 1. `server/main.py` 상단 import에 `base64` 추가

```python
import base64
```

이미 있으면 추가하지 마라.

### 2. 쿠키 저장 로직 수정 (358~363행 부근)

**현재 코드 (이것을 찾아라):**
```python
        # Railway 환경변수 YOUTUBE_COOKIES 값을 임시 파일로 저장
        cookie_file = "/tmp/youtube_cookies.txt"
        cookie_content = os.getenv("YOUTUBE_COOKIES", "")
        if cookie_content:
            with open(cookie_file, "w", encoding="utf-8") as f:
                f.write(cookie_content)
```

**변경할 코드 (이것으로 교체하라):**
```python
        # Railway 환경변수 YOUTUBE_COOKIES (base64 인코딩됨) → 디코딩하여 파일로 저장
        cookie_file = "/tmp/youtube_cookies.txt"
        cookie_content = os.getenv("YOUTUBE_COOKIES", "")
        if cookie_content:
            try:
                decoded = base64.b64decode(cookie_content).decode("utf-8")
                with open(cookie_file, "w", encoding="utf-8") as f:
                    f.write(decoded)
            except Exception:
                # base64가 아닌 경우 (하위호환) 그대로 저장
                with open(cookie_file, "w", encoding="utf-8") as f:
                    f.write(cookie_content)
```

### 3. 나머지 코드는 절대 건드리지 마라

- `--js-runtimes node` → 유지
- `--sleep-requests`, `--min-sleep-interval`, `--max-sleep-interval` → 유지
- `--cookies` 옵션 로직 → 유지
- Dockerfile → 변경 없음

---

## 변경 범위 요약

| 항목 | 변경 |
|------|------|
| `import base64` | 추가 (없으면) |
| 쿠키 저장 로직 (358~363행) | base64 디코딩 + try/except 폴백 |
| 그 외 모든 코드 | **변경 금지** |

---

## 작업 완료 후 할 일

1. `git add server/main.py`
2. `git commit -m "fix: YOUTUBE_COOKIES base64 디코딩 적용 (줄바꿈 보존)"`
3. `git push origin main`
4. 사용자에게 푸시 완료 알림

---

## 사용자가 이후 할 작업 (참고용, Antigravity가 하는 게 아님)

사용자가 PC에서 다음을 수행:
1. Chrome 확장프로그램으로 YouTube 쿠키를 Netscape format으로 내보내기
2. 터미널에서 base64 인코딩:
   - **Windows PowerShell**: `[Convert]::ToBase64String([IO.File]::ReadAllBytes("cookies.txt"))`
   - **Mac/Linux**: `base64 -w 0 cookies.txt`
3. 인코딩된 문자열을 Railway `YOUTUBE_COOKIES` 환경변수에 붙여넣기

---

## 주의사항

- **다른 방법 시도하지 마라** (OAuth, 프록시, 다른 라이브러리 등)
- **다른 파일 수정하지 마라** (Dockerfile, requirements.txt 등)
- **기존 yt-dlp 옵션 제거하지 마라**
- base64 디코딩 실패 시 기존 방식으로 폴백하는 `except` 블록은 반드시 유지해라 (하위호환)
