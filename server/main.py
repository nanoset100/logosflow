import os
import json
import uuid
import tempfile
import asyncio
import base64
import urllib.parse
from pathlib import Path
from fastapi import FastAPI, UploadFile, File, Form, HTTPException, Header
from fastapi.responses import Response, HTMLResponse
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
from openai import AsyncOpenAI, OpenAIError
from groq import AsyncGroq
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

# Groq 클라이언트 (Whisper 전용 - 무료)
_groq_key = os.getenv("GROQ_API_KEY")
groq_client = AsyncGroq(api_key=_groq_key) if _groq_key else None

MAX_WHISPER_BYTES = 24 * 1024 * 1024  # 24MB
MAX_CHUNK_SECONDS = 1200  # 20분 청크 분할 기준

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


async def get_audio_duration(audio_path: str) -> float:
    """ffprobe로 오디오 길이(초) 반환"""
    cmd = [
        "ffprobe", "-v", "quiet", "-print_format", "json",
        "-show_format", audio_path,
    ]
    proc = await asyncio.create_subprocess_exec(
        *cmd,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
    )
    stdout, _ = await proc.communicate()
    if proc.returncode != 0:
        return 0.0
    try:
        data = json.loads(stdout.decode())
        return float(data.get("format", {}).get("duration", 0))
    except Exception:
        return 0.0


async def split_into_chunks(input_path: str, chunk_dir: str) -> list:
    """오디오를 20분 청크로 분할 + 압축 (64kbps mono 16kHz)"""
    output_pattern = str(Path(chunk_dir) / "chunk_%03d.mp3")
    cmd = [
        "ffmpeg", "-y", "-i", input_path,
        "-f", "segment", "-segment_time", str(MAX_CHUNK_SECONDS),
        "-vn", "-ar", "16000", "-ac", "1", "-b:a", "64k",
        output_pattern,
    ]
    proc = await asyncio.create_subprocess_exec(
        *cmd,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
    )
    _, stderr = await proc.communicate()
    if proc.returncode != 0:
        raise HTTPException(status_code=500, detail=f"오디오 분할 오류: {stderr.decode()[:200]}")
    return sorted(str(p) for p in Path(chunk_dir).glob("chunk_*.mp3"))


async def _call_whisper(audio_path: str, language: str) -> str:
    import io
    audio_bytes = Path(audio_path).read_bytes()
    filename = Path(audio_path).name

    if groq_client:
        try:
            result = await groq_client.audio.transcriptions.create(
                model="whisper-large-v3-turbo",
                file=(filename, io.BytesIO(audio_bytes), "audio/mpeg"),
                language=language,
                response_format="text",
            )
            return result if isinstance(result, str) else str(result)
        except Exception as e:
            err = str(e)
            if "429" in err or "rate_limit" in err.lower():
                print(f"[Whisper] Groq 429 한도 초과 → OpenAI 폴백")
            else:
                raise HTTPException(status_code=500, detail=f"Whisper API 오류: {err}")

    # Groq 미설정 또는 429 → OpenAI Whisper
    try:
        result = await client.audio.transcriptions.create(
            model="whisper-1",
            file=(filename, io.BytesIO(audio_bytes)),
            language=language,
            response_format="text",
        )
        return result if isinstance(result, str) else str(result)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Whisper API 오류: {str(e)}")


async def transcribe_file(audio_path: str, language: str = "ko") -> str:
    duration = await get_audio_duration(audio_path)

    if duration > MAX_CHUNK_SECONDS:
        # 20분 초과: 청크로 분할 후 순차 STT
        with tempfile.TemporaryDirectory() as chunk_dir:
            chunks = await split_into_chunks(audio_path, chunk_dir)
            if not chunks:
                raise HTTPException(status_code=500, detail="오디오 분할 실패")
            try:
                texts = []
                for chunk_path in chunks:
                    text = await _call_whisper(chunk_path, language)
                    texts.append(text.strip())
                return " ".join(t for t in texts if t)
            except Exception as e:
                raise HTTPException(status_code=500, detail=f"Whisper API 오류: {str(e)}")
    else:
        # 20분 이하: 필요 시 압축 후 STT
        file_size = Path(audio_path).stat().st_size
        if file_size > MAX_WHISPER_BYTES:
            compressed_path = audio_path + "_compressed.mp3"
            await compress_audio(audio_path, compressed_path)
            transcribe_path = compressed_path
        else:
            transcribe_path = audio_path

        try:
            return await _call_whisper(transcribe_path, language)
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Whisper API 오류: {str(e)}")
        finally:
            if file_size > MAX_WHISPER_BYTES:
                Path(transcribe_path).unlink(missing_ok=True)


@app.get("/", response_class=HTMLResponse)
async def landing_page():
    html_path = Path(__file__).parent / "landing.html"
    return HTMLResponse(content=html_path.read_text(encoding="utf-8"))


@app.get("/daily", response_class=HTMLResponse)
async def landing_daily():
    html_path = Path(__file__).parent / "landing_daily.html"
    return HTMLResponse(content=html_path.read_text(encoding="utf-8"))


@app.get("/health")
async def health():
    return {
        "status": "ok",
        "service": "chimshin-whisper",
        "stt_provider": "groq" if groq_client else "openai",
        "tts_provider": "openai",
        "ai_provider": "openai",
    }


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


class PrayerRequest(BaseModel):
    prayer_type: str  # 예배 종류 (예: 주일예배, 새벽예배)


@app.post("/ai/prayer")
async def generate_prayer(req: PrayerRequest, x_app_key: str = Header("")):
    _verify_app_key(x_app_key)
    if not req.prayer_type.strip():
        raise HTTPException(status_code=400, detail="예배 종류가 비어 있습니다")

    system_prompt = f"""당신은 교회 예배를 위한 대표기도문 작성을 도와주는 목사님입니다.
기도문의 길이는 천천히 읽었을 때 약 5분 정도 걸리도록 작성해주세요.
이를 위해 다음 사항을 꼭 지켜주세요:
1. '하느님'이라는 표현은 절대로 사용하지 말고, 항상 '하나님'으로 통일하여 표현합니다.
2. 기도의 마무리는 반드시 "예수님의 이름으로 기도합니다."라는 표현으로 끝내야 합니다.
3. 예배, 찬양과 감사, 죄에 대한 고백, 회중 전체의 염원과 소망, 말씀과 목회자를 담은 간구.
4. 대표기도문에는 반드시 입력한 예배 이름 "{req.prayer_type}"을(를) 1회 이상 언급해주세요.
5. 각 문장마다 자연스러운 쉼표나 마침표를 사용하여 숨을 쉴 수 있도록 합니다.
6. 어려운 단어를 피하고 누구나 쉽게 이해할 수 있는 단어를 사용합니다.
7. 문단을 명확하게 나누어 전체적으로 깔끔한 느낌을 줍니다.
8. 핵심 메시지를 중심으로 문장을 구성하여 집중력을 유지할 수 있도록 합니다.
9. 기도의 흐름이 자연스럽고, 듣는 이의 마음에 잘 와닿도록 작성합니다.
10. 기도의 길이는 천천히 읽었을 때 약 5분 분량으로 (1000-1200자).
11. 의미 없이 반복되는 표현을 피하고, 진심을 담아 정중하고 은혜롭게 작성해주세요.
12. 기도의 시작부터 마침까지 자연스러운 흐름을 유지하여 듣는 사람이 끝까지 집중할 수 있도록 합니다.
13. 만약 예배 이름({req.prayer_type})에 '부활절', '성탄절', '사순절', '성령강림절', '맥추감사절', '추수감사절' 등 기독교 절기가 포함되어 있다면, 해당 절기가 갖는 신학적 의미와 감사의 고백을 기도 내용에 자연스럽게 포함하여 작성해주세요.

[절대 필수] 기도문의 마지막 문장은 반드시 "예수님의 이름으로 기도합니다. 아멘."으로 끝내야 합니다. 이 문장이 빠지면 기도문이 완성되지 않은 것입니다."""

    try:
        completion = await client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": "대표기도문을 작성해주세요."},
            ],
            max_tokens=3500,
            temperature=0.7,
        )
        prayer = completion.choices[0].message.content.strip()
    except OpenAIError as e:
        raise HTTPException(status_code=500, detail=f"AI 오류: {str(e)}")

    return {"prayer": prayer}


class TtsRequest(BaseModel):
    text: str
    voice: str = "alloy"  # alloy(남성) | nova(여성)


def _verify_app_key(x_app_key: str = ""):
    expected = os.getenv("NOTIFY_SERVER_KEY")
    if not expected or x_app_key != expected:
        raise HTTPException(status_code=403, detail="인증 실패")


async def _generate_tts_bytes(text: str, voice: str) -> bytes:
    response = await client.audio.speech.create(
        model="tts-1",
        voice=voice,
        input=text[:4000],  # OpenAI TTS 4096자 제한
    )
    return response.content


async def _upload_to_firebase_storage(audio_bytes: bytes, blob_path: str) -> str:
    """Firebase Storage에 업로드 후 다운로드 URL 반환"""
    bucket_name = os.getenv("FIREBASE_STORAGE_BUCKET")
    if not bucket_name:
        raise HTTPException(status_code=503, detail="FIREBASE_STORAGE_BUCKET 미설정")
    bucket = firebase_admin.storage.bucket(bucket_name)
    blob = bucket.blob(blob_path)
    blob.upload_from_string(audio_bytes, content_type="audio/mpeg")
    token = str(uuid.uuid4())
    blob.metadata = {"firebaseStorageDownloadTokens": token}
    blob.patch()
    encoded = urllib.parse.quote(blob_path, safe="")
    return f"https://firebasestorage.googleapis.com/v0/b/{bucket_name}/o/{encoded}?alt=media&token={token}"


@app.post("/ai/tts")
async def text_to_speech(req: TtsRequest, x_app_key: str = Header("")):
    _verify_app_key(x_app_key)
    allowed_voices = {"alloy", "nova", "echo", "fable", "onyx", "shimmer"}
    if req.voice not in allowed_voices:
        raise HTTPException(status_code=400, detail=f"지원하지 않는 음성: {req.voice}")
    if not req.text.strip():
        raise HTTPException(status_code=400, detail="텍스트가 비어 있습니다")

    try:
        audio_bytes = await _generate_tts_bytes(req.text, req.voice)
    except OpenAIError as e:
        raise HTTPException(status_code=500, detail=f"TTS 오류: {str(e)}")

    return Response(content=audio_bytes, media_type="audio/mpeg")


@app.post("/ai/tts/cache")
async def tts_cache(
    text: str = Form(...),
    voice: str = Form(default="alloy"),
    church_code: str = Form(...),
    sermon_id: str = Form(...),
    x_app_key: str = Header(""),
):
    """설교 TTS를 Firebase Storage에 캐싱 - 관리자 설교 등록 시 1회 호출"""
    _verify_app_key(x_app_key)
    if not text.strip():
        raise HTTPException(status_code=400, detail="텍스트가 비어 있습니다")
    allowed_voices = {"alloy", "nova"}
    if voice not in allowed_voices:
        raise HTTPException(status_code=400, detail=f"지원하지 않는 음성: {voice}")

    try:
        audio_bytes = await _generate_tts_bytes(text, voice)
    except OpenAIError as e:
        raise HTTPException(status_code=500, detail=f"TTS 오류: {str(e)}")

    blob_path = f"sermons/{church_code}/{sermon_id}/tts_{voice}.mp3"
    try:
        url = await _upload_to_firebase_storage(audio_bytes, blob_path)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Storage 업로드 오류: {str(e)}")

    return {"url": url, "voice": voice}


class AnalyzeRequest(BaseModel):
    text: str


@app.post("/ai/analyze")
async def analyze_sermon(req: AnalyzeRequest, x_app_key: str = Header("")):
    _verify_app_key(x_app_key)
    if not req.text.strip():
        raise HTTPException(status_code=400, detail="분석할 텍스트가 없습니다")

    truncated = req.text[:10000] if len(req.text) > 10000 else req.text

    system_prompt = (
        "당신은 한국 침례교회의 설교 전문 분석가입니다. "
        "설교 텍스트를 분석하여 성도들의 신앙 성장을 돕는 요약과 6일 묵상(월~토)을 작성합니다. "
        "신학적으로 정확하고 평신도가 이해하기 쉬운 언어를 사용하세요. "
        "반드시 JSON 형식만 반환하고 추가 설명은 쓰지 마세요.\n\n"
        "[절대 필수 규칙]\n"
        "1. summary 필드는 반드시 두 부분으로 구성합니다:\n"
        "   Part 1) 설교 전체 요약 3개 문단 (각 문단 사이 빈 줄)\n"
        "   Part 2) '핵심 교훈' 섹션 — 이 섹션은 절대 생략 불가입니다.\n"
        "      형식: 핵심 교훈\\n\\n- **제목**\\n내용 (3개 이상 항목 필수)\n"
        "2. 핵심 교훈 섹션이 없으면 응답이 무효입니다. 반드시 포함하세요.\n"
        "3. day1~day6은 반드시 아래 형식으로 작성합니다:\n"
        "   **[요일] 제목**\\n\\n**오늘의 말씀**: 설교 핵심 구절 또는 문장 (큰따옴표로 감싸기)\\n\\n"
        "   **묵상**: 2~3문장 묵상 내용\\n\\n**적용**: 오늘 하루 구체적 실천 행동 1~2가지"
    )

    user_prompt = f"""다음 설교 텍스트를 분석하여 JSON으로만 응답해주세요.

[summary 필드 구조 — 반드시 이 순서대로 작성]
① 3개 문단 요약 (문단 사이 빈 줄)
② 빈 줄
③ 핵심 교훈  ← 이 줄 반드시 포함
④ 빈 줄
⑤ - **교훈 제목**: 내용 (3개 이상 필수)

[day1~day6 필드 구조 — 반드시 이 형식으로 작성]
**[요일] 제목**

**오늘의 말씀**: "설교 핵심 구절 또는 문장"

**묵상**: 이 진리가 우리 삶에 주는 의미를 2~3문장으로 서술

**적용**: 오늘 하루 구체적으로 실천할 수 있는 행동 1~2가지

설교 텍스트:
{truncated}

응답 형식 (JSON만, 한국어로):
{{
  "summary": "문단1 내용...\\n\\n문단2 내용...\\n\\n문단3 내용...\\n\\n핵심 교훈\\n\\n- **교훈 제목1**\\n내용 2~3문장.\\n\\n- **교훈 제목2**\\n내용 2~3문장.\\n\\n- **교훈 제목3**\\n내용 2~3문장.",
  "day1": "**[월요일] 제목**\\n\\n**오늘의 말씀**: \\"설교 핵심 구절\\"\\n\\n**묵상**: 묵상 내용 2~3문장.\\n\\n**적용**: 오늘 실천할 행동 1~2가지.",
  "day2": "**[화요일] 제목**\\n\\n**오늘의 말씀**: \\"설교 핵심 구절\\"\\n\\n**묵상**: 묵상 내용 2~3문장.\\n\\n**적용**: 오늘 실천할 행동 1~2가지.",
  "day3": "**[수요일] 제목**\\n\\n**오늘의 말씀**: \\"설교 핵심 구절\\"\\n\\n**묵상**: 묵상 내용 2~3문장.\\n\\n**적용**: 오늘 실천할 행동 1~2가지.",
  "day4": "**[목요일] 제목**\\n\\n**오늘의 말씀**: \\"설교 핵심 구절\\"\\n\\n**묵상**: 묵상 내용 2~3문장.\\n\\n**적용**: 오늘 실천할 행동 1~2가지.",
  "day5": "**[금요일] 제목**\\n\\n**오늘의 말씀**: \\"설교 핵심 구절\\"\\n\\n**묵상**: 묵상 내용 2~3문장.\\n\\n**적용**: 오늘 실천할 행동 1~2가지.",
  "day6": "**[토요일] 제목**\\n\\n**오늘의 말씀**: \\"설교 핵심 구절\\"\\n\\n**묵상**: 한 주를 돌아보며 묵상 2~3문장.\\n\\n**적용**: 주변 사람에게 말씀의 소망을 나누는 행동 1~2가지."
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
