import os
import json
import tempfile
import asyncio
import base64
from pathlib import Path
from fastapi import FastAPI, UploadFile, File, Form, HTTPException, Header
from fastapi.responses import Response, HTMLResponse
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
from openai import AsyncOpenAI, OpenAIError
from dotenv import load_dotenv

load_dotenv()

# yt-dlp 자동 업데이트 (YouTube API 변경 대응)
try:
    import subprocess as _sp
    _sp.run(["yt-dlp", "-U"], capture_output=True, timeout=30)
except Exception:
    pass

_openai_key = os.getenv("OPENAI_API_KEY")
if not _openai_key:
    raise RuntimeError("OPENAI_API_KEY 환경변수가 설정되지 않았습니다")

client = AsyncOpenAI(api_key=_openai_key)

MAX_WHISPER_BYTES = 24 * 1024 * 1024  # 24MB

# ─── Firebase Admin 초기화 (FCM 푸시 알림용) ──────────────────────────────────
import firebase_admin
from firebase_admin import credentials, messaging as fcm_messaging

_firebase_initialized = False

def _init_firebase():
    global _firebase_initialized
    if _firebase_initialized:
        return True
    # 이미 다른 임포트에서 초기화된 경우 (uvicorn 이중 임포트 대응)
    if firebase_admin._apps:
        _firebase_initialized = True
        print("[FCM] Firebase Admin 이미 초기화됨 (재사용)")
        return True
    service_account_json = os.getenv("FIREBASE_SERVICE_ACCOUNT")
    if not service_account_json:
        print("[FCM] FIREBASE_SERVICE_ACCOUNT 환경변수 없음 - 푸시 알림 비활성화")
        return False
    try:
        cred_dict = json.loads(service_account_json)
        cred = credentials.Certificate(cred_dict)
        firebase_admin.initialize_app(cred)
        _firebase_initialized = True
        print("[FCM] Firebase Admin 초기화 완료")
        return True
    except Exception as e:
        print(f"[FCM] Firebase Admin 초기화 실패: {e}")
        return False

_init_firebase()

# ─── APScheduler: 매일 오전 7시 KST 묵상 알림 ───────────────────────────────
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
import pytz

_scheduler = AsyncIOScheduler(timezone=pytz.timezone("Asia/Seoul"))

async def _send_daily_devotion_notification():
    """매일 오전 7:00 KST - daily_devotion 토픽으로 묵상 알림 발송"""
    if not _firebase_initialized:
        print("[FCM] Firebase 미초기화 - 알림 발송 건너뜀")
        return
    try:
        from datetime import datetime
        weekdays = ["월", "화", "수", "목", "금", "토", "일"]
        today = weekdays[datetime.now(pytz.timezone("Asia/Seoul")).weekday()]

        daily_messages = {
            "월": "한 주의 시작, 말씀으로 힘을 얻으세요 💪",
            "화": "어제 말씀 묵상 하셨나요? 오늘도 함께해요 🙏",
            "수": "한 주의 중심에서 말씀을 붙드세요 ✝️",
            "목": "주일 설교 말씀을 다시 되새겨보세요 📖",
            "금": "이번 주 마지막 묵상, 감사로 마무리해요 🌟",
            "토": "주일을 준비하는 마음으로 말씀을 묵상해요 🕊️",
            "일": "예배 후 말씀을 마음에 새겨보세요 ⛪",
        }
        body = daily_messages.get(today, "오늘의 묵상 말씀을 확인해보세요 🙏")

        message = fcm_messaging.Message(
            notification=fcm_messaging.Notification(
                title=f"📖 {today}요일 말씀 묵상",
                body=body,
            ),
            topic="daily_devotion",
            android=fcm_messaging.AndroidConfig(
                notification=fcm_messaging.AndroidNotification(
                    icon="ic_launcher",
                    color="#1A6B3A",
                    sound="default",
                ),
                priority="high",
            ),
            apns=fcm_messaging.APNSConfig(
                payload=fcm_messaging.APNSPayload(
                    aps=fcm_messaging.Aps(sound="default", badge=1),
                ),
            ),
        )
        response = fcm_messaging.send(message)
        print(f"[FCM] 묵상 알림 발송 완료: {response}")
    except Exception as e:
        print(f"[FCM] 알림 발송 실패: {e}")

async def _check_absent_members():
    """매주 월요일 오전 9:00 KST - 21일 이상 미출석 교인 목사님에게 알림"""
    if not _firebase_initialized:
        return
    try:
        from firebase_admin import firestore as admin_firestore
        from datetime import datetime, timedelta
        db = admin_firestore.client()
        kst = pytz.timezone("Asia/Seoul")
        now = datetime.now(kst)
        threshold = now - timedelta(days=21)

        churches = db.collection('churches').stream()
        total = 0
        for church in churches:
            church_data = church.to_dict()
            admin_tokens = church_data.get('adminFcmTokens', [])
            if not admin_tokens:
                continue

            members = (db.collection('churches').document(church.id)
                       .collection('members').stream())
            absent = []
            for m in members:
                data = m.to_dict()
                last_active = data.get('lastActiveAt')
                joined_at = data.get('joinedAt')
                name = data.get('name', '?')
                role = data.get('role', '성도')

                if last_active is None:
                    if joined_at and joined_at.timestamp() < threshold.timestamp():
                        absent.append(f"{name} {role}")
                elif last_active.timestamp() < threshold.timestamp():
                    absent.append(f"{name} {role}")

            if not absent:
                continue

            names = ', '.join(absent[:3])
            more = f" 외 {len(absent)-3}명" if len(absent) > 3 else ""
            for token in set(admin_tokens):
                msg = fcm_messaging.Message(
                    notification=fcm_messaging.Notification(
                        title="⚠️ 미출석 교인 알림",
                        body=f"{names}{more}님이 3주 이상 접속하지 않았습니다",
                    ),
                    data={'type': 'absent', 'count': str(len(absent))},
                    token=token,
                    android=fcm_messaging.AndroidConfig(priority="high"),
                )
                fcm_messaging.send(msg)
                total += 1
        print(f"[Absent] 미출석 알림 {total}건 발송 완료")
    except Exception as e:
        print(f"[Absent] 미출석 알림 실패: {e}")


async def _send_birthday_notifications():
    """매일 오전 6:00 KST - 오늘 생일인 교인을 목사님에게 알림"""
    if not _firebase_initialized:
        return
    try:
        from firebase_admin import firestore as admin_firestore
        from datetime import datetime
        db = admin_firestore.client()
        kst = pytz.timezone("Asia/Seoul")
        today = datetime.now(kst)
        month, day = today.month, today.day

        churches = db.collection('churches').stream()
        count = 0
        for church in churches:
            church_data = church.to_dict()
            admin_tokens = church_data.get('adminFcmTokens', [])
            if not admin_tokens:
                continue

            # 오늘 생일인 교인 조회
            members = (db.collection('churches').document(church.id)
                       .collection('members')
                       .where('birthMonth', '==', month)
                       .where('birthDay', '==', day)
                       .stream())

            birthday_members = [(m.to_dict().get('name', '?'), m.to_dict().get('role', '성도'))
                                for m in members]
            if not birthday_members:
                continue

            # 목사님 전체에게 알림
            for token in set(admin_tokens):
                for name, role in birthday_members:
                    msg = fcm_messaging.Message(
                        notification=fcm_messaging.Notification(
                            title=f"🎂 오늘 교인 생일",
                            body=f"{name} {role}님이 오늘 생일입니다 🎉",
                        ),
                        data={'type': 'birthday', 'memberName': name},
                        token=token,
                        android=fcm_messaging.AndroidConfig(priority="high"),
                    )
                    fcm_messaging.send(msg)
                    count += 1
        print(f"[Birthday] 생일 알림 {count}건 발송 완료 ({month}/{day})")
    except Exception as e:
        print(f"[Birthday] 생일 알림 실패: {e}")


app = FastAPI(title="Chimshin Whisper Server", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://logosflow-production.up.railway.app",
        "http://localhost:8000",
        "http://localhost:3000",
    ],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
async def startup_event():
    # 매일 오전 7시 KST 묵상 알림 스케줄러 시작
    _scheduler.add_job(
        _send_daily_devotion_notification,
        CronTrigger(hour=7, minute=0, timezone=pytz.timezone("Asia/Seoul")),
        id="daily_devotion",
        replace_existing=True,
    )
    _scheduler.add_job(
        _send_birthday_notifications,
        CronTrigger(hour=6, minute=0, timezone=pytz.timezone("Asia/Seoul")),
        id="birthday_check",
        replace_existing=True,
    )
    _scheduler.add_job(
        _check_absent_members,
        CronTrigger(day_of_week="mon", hour=9, minute=0, timezone=pytz.timezone("Asia/Seoul")),
        id="absent_check",
        replace_existing=True,
    )
    _scheduler.start()
    print("[Scheduler] 07:00 묵상 + 06:00 생일 + 월09:00 미출석 스케줄러 시작")


@app.on_event("shutdown")
async def shutdown_event():
    _scheduler.shutdown(wait=False)


async def compress_audio(input_path: str, output_path: str) -> None:
    cmd = [
        "ffmpeg", "-y", "-i", input_path,
        "-vn", "-ar", "16000", "-ac", "1",
        "-b:a", "64k", output_path,
    ]
    proc = await asyncio.create_subprocess_exec(
        *cmd,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
    )
    _, stderr = await proc.communicate()
    if proc.returncode != 0:
        raise HTTPException(status_code=500, detail=f"ffmpeg 오류: {stderr.decode()}")


async def transcribe_file(audio_path: str, language: str = "ko") -> str:
    file_size = Path(audio_path).stat().st_size

    if file_size > MAX_WHISPER_BYTES:
        compressed_path = audio_path + "_compressed.mp3"
        await compress_audio(audio_path, compressed_path)
        transcribe_path = compressed_path
    else:
        transcribe_path = audio_path

    try:
        with open(transcribe_path, "rb") as f:
            result = await client.audio.transcriptions.create(
                model="whisper-1",
                file=f,
                language=language,
                response_format="text",
            )
    except OpenAIError as e:
        raise HTTPException(status_code=500, detail=f"Whisper API 오류: {str(e)}")
    finally:
        if file_size > MAX_WHISPER_BYTES:
            Path(transcribe_path).unlink(missing_ok=True)

    return result if isinstance(result, str) else str(result)


@app.get("/", response_class=HTMLResponse)
async def landing_page():
    html_path = Path(__file__).parent / "landing.html"
    return HTMLResponse(content=html_path.read_text(encoding="utf-8"))


@app.get("/health")
async def health():
    return {"status": "ok", "service": "chimshin-whisper"}


@app.post("/transcribe")
async def transcribe_audio(
    file: UploadFile = File(...),
    language: str = Form(default="ko"),
):
    allowed = {".mp3", ".mp4", ".m4a", ".wav", ".webm", ".ogg", ".flac", ".aac"}
    ext = Path(file.filename or "audio.mp3").suffix.lower()
    if ext not in allowed:
        raise HTTPException(status_code=400, detail=f"지원하지 않는 파일 형식: {ext}")

    with tempfile.NamedTemporaryFile(suffix=ext, delete=False) as tmp:
        tmp.write(await file.read())
        tmp_path = tmp.name

    try:
        text = await transcribe_file(tmp_path, language)
    finally:
        Path(tmp_path).unlink(missing_ok=True)

    if not text.strip():
        raise HTTPException(status_code=422, detail="음성을 인식할 수 없습니다. 녹음 상태를 확인해주세요.")

    return {"text": text, "language": language}


@app.post("/transcribe/youtube")
async def transcribe_youtube(
    url: str = Form(...),
    language: str = Form(default="ko"),
):
    if "youtube.com" not in url and "youtu.be" not in url:
        raise HTTPException(status_code=400, detail="유효한 YouTube URL이 아닙니다")

    with tempfile.TemporaryDirectory() as tmpdir:
        output_path = str(Path(tmpdir) / "audio")

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

        proxy_url = os.getenv("PROXY_URL", "")

        cmd = [
            "yt-dlp", "-x", "--audio-format", "mp3",
            "--audio-quality", "64K", "--no-playlist",
            "--js-runtimes", "node",
            "--sleep-requests", "1",
            "--min-sleep-interval", "1",
            "--max-sleep-interval", "3",
            "-o", output_path + ".%(ext)s",
        ]

        if proxy_url:
            cmd += ["--proxy", proxy_url]

        # 쿠키 파일이 존재하면 --cookies 옵션 추가
        if cookie_content and Path(cookie_file).exists():
            cmd += ["--cookies", cookie_file]

        cmd.append(url)

        proc = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        _, stderr = await proc.communicate()

        if proc.returncode != 0:
            err = stderr.decode(errors="replace")
            print(f"[yt-dlp ERROR] returncode={proc.returncode}\n{err[:2000]}")
            if "Private video" in err or "members-only" in err:
                raise HTTPException(status_code=403, detail="비공개 또는 멤버십 전용 영상입니다")
            raise HTTPException(status_code=500, detail=f"YouTube 오디오 추출 실패: {err[:300]}")

        mp3_path = output_path + ".mp3"
        if not Path(mp3_path).exists():
            raise HTTPException(status_code=500, detail="오디오 파일을 찾을 수 없습니다")

        text = await transcribe_file(mp3_path, language)

    if not text.strip():
        raise HTTPException(status_code=422, detail="음성을 인식할 수 없습니다.")

    return {"text": text, "language": language}


class TtsRequest(BaseModel):
    text: str
    voice: str = "alloy"  # alloy(남성) | nova(여성)


@app.post("/ai/tts")
async def text_to_speech(req: TtsRequest):
    allowed_voices = {"alloy", "nova", "echo", "fable", "onyx", "shimmer"}
    if req.voice not in allowed_voices:
        raise HTTPException(status_code=400, detail=f"지원하지 않는 음성: {req.voice}")
    if not req.text.strip():
        raise HTTPException(status_code=400, detail="텍스트가 비어 있습니다")

    try:
        response = await client.audio.speech.create(
            model="tts-1",
            voice=req.voice,
            input=req.text,
        )
        audio_bytes = response.content
    except OpenAIError as e:
        raise HTTPException(status_code=500, detail=f"TTS 오류: {str(e)}")

    return Response(content=audio_bytes, media_type="audio/mpeg")


class AnalyzeRequest(BaseModel):
    text: str


@app.post("/ai/analyze")
async def analyze_sermon(req: AnalyzeRequest):
    if not req.text.strip():
        raise HTTPException(status_code=400, detail="분석할 텍스트가 없습니다")

    truncated = req.text[:10000] if len(req.text) > 10000 else req.text

    system_prompt = (
        "당신은 한국 침례교회의 설교 전문 분석가입니다. "
        "설교 텍스트를 분석하여 성도들의 신앙 성장을 돕는 요약과 5일 묵상을 작성합니다. "
        "신학적으로 정확하고 평신도가 이해하기 쉬운 언어를 사용하세요. "
        "반드시 JSON 형식만 반환하고 추가 설명은 쓰지 마세요.\n\n"
        "[절대 필수 규칙]\n"
        "1. summary 필드는 반드시 두 부분으로 구성합니다:\n"
        "   Part 1) 설교 전체 요약 3개 문단 (각 문단 사이 빈 줄)\n"
        "   Part 2) '핵심 교훈' 섹션 — 이 섹션은 절대 생략 불가입니다.\n"
        "      형식: 핵심 교훈\\n\\n- **제목**\\n내용 (3개 이상 항목 필수)\n"
        "2. 핵심 교훈 섹션이 없으면 응답이 무효입니다. 반드시 포함하세요."
    )

    user_prompt = f"""다음 설교 텍스트를 분석하여 JSON으로만 응답해주세요.

[summary 필드 구조 — 반드시 이 순서대로 작성]
① 3개 문단 요약 (문단 사이 빈 줄)
② 빈 줄
③ 핵심 교훈  ← 이 줄 반드시 포함
④ 빈 줄
⑤ - **교훈 제목**: 내용 (3개 이상 필수)

설교 텍스트:
{truncated}

응답 형식 (JSON만, 한국어로):
{{
  "summary": "문단1 내용...\\n\\n문단2 내용...\\n\\n문단3 내용...\\n\\n핵심 교훈\\n\\n- **교훈 제목1**\\n내용 2~3문장.\\n\\n- **교훈 제목2**\\n내용 2~3문장.\\n\\n- **교훈 제목3**\\n내용 2~3문장.",
  "day1": "Day 1: [제목]\\n\\n핵심 진리 2~3문장.\\n\\nReflection: 이 진리가 오늘 나의 삶에 어떤 의미를 주는가?",
  "day2": "Day 2: [제목]\\n\\n적용 방법 2~3문장.\\n\\nReflection: 오늘 하루 실천할 수 있는 한 가지 행동은 무엇인가?",
  "day3": "Day 3: [제목]\\n\\n기도 제목과 기도 2~3문장.\\n\\nReflection: 하나님께 어떤 마음으로 기도할 것인가?",
  "day4": "Day 4: [제목]\\n\\n이번 주 실천할 변화 2~3문장.\\n\\nReflection: 이 말씀이 나의 관계와 일상을 어떻게 바꾸는가?",
  "day5": "Day 5: [제목]\\n\\n구역/셀 모임 나눔 2~3문장.\\n\\nReflection: 이번 주 말씀을 통해 공동체와 나누고 싶은 것은?"
}}"""

    try:
        completion = await client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            temperature=0.7,
            max_tokens=4000,
            response_format={"type": "json_object"},
        )
        content = completion.choices[0].message.content
        import json
        result = json.loads(content)
    except OpenAIError as e:
        raise HTTPException(status_code=500, detail=f"AI 오류: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"응답 파싱 오류: {str(e)}")

    return result


class NotifyTopicRequest(BaseModel):
    topic: str  # e.g. "daily_devotion"
    title: str
    body: str
    server_key: str  # 서버 호출 인증용 비밀키


class NotifyTokenRequest(BaseModel):
    token: str  # FCM 개별 토큰
    title: str
    body: str
    data: dict = {}
    server_key: str = ""  # 레거시 지원 (optional)


def _verify_auth(server_key: str = "", authorization: str = ""):
    """Firebase Auth 토큰 또는 레거시 server_key로 인증"""
    # 1. Firebase Auth 토큰 검증 (Bearer token)
    if authorization.startswith("Bearer "):
        try:
            from firebase_admin import auth as fb_auth
            token = authorization.replace("Bearer ", "")
            fb_auth.verify_id_token(token)
            return  # 인증 성공
        except Exception:
            pass

    # 2. 레거시 server_key 검증 (하위 호환)
    expected = os.getenv("NOTIFY_SERVER_KEY")
    if expected and server_key == expected:
        return  # 인증 성공

    raise HTTPException(status_code=403, detail="인증 실패")


@app.post("/notify/topic")
async def notify_topic(req: NotifyTopicRequest, authorization: str = Header("")):
    """토픽 구독자 전체에게 푸시 알림 발송 (관리자 전용)"""
    _verify_auth(req.server_key, authorization)
    if not _firebase_initialized:
        raise HTTPException(status_code=503, detail="Firebase 초기화 안 됨")
    try:
        message = fcm_messaging.Message(
            notification=fcm_messaging.Notification(title=req.title, body=req.body),
            topic=req.topic,
        )
        response = fcm_messaging.send(message)
        return {"success": True, "message_id": response}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/notify/token")
async def notify_token(req: NotifyTokenRequest, authorization: str = Header("")):
    """특정 FCM 토큰으로 개인 알림 발송 (목사님 목양 알림용)"""
    _verify_auth(req.server_key, authorization)
    if not _firebase_initialized:
        raise HTTPException(status_code=503, detail="Firebase 초기화 안 됨")
    try:
        message = fcm_messaging.Message(
            notification=fcm_messaging.Notification(title=req.title, body=req.body),
            data={k: str(v) for k, v in req.data.items()},
            token=req.token,
        )
        response = fcm_messaging.send(message)
        return {"success": True, "message_id": response}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    uvicorn.run("main:app", host="0.0.0.0", port=port)
