import os
import json
import tempfile
import asyncio
from pathlib import Path
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.responses import Response
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

        message = fcm_messaging.Message(
            notification=fcm_messaging.Notification(
                title=f"오늘의 말씀 묵상 ({today}요일)",
                body="오늘의 묵상 말씀을 확인해보세요 🙏",
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

app = FastAPI(title="Chimshin Whisper Server", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
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
    _scheduler.start()
    print("[Scheduler] 매일 07:00 KST 묵상 알림 스케줄러 시작")


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
        cmd = [
            "yt-dlp", "-x", "--audio-format", "mp3",
            "--audio-quality", "64K", "--no-playlist",
            "-o", output_path + ".%(ext)s", url,
        ]
        proc = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        _, stderr = await proc.communicate()

        if proc.returncode != 0:
            err = stderr.decode()
            if "Private video" in err or "members-only" in err:
                raise HTTPException(status_code=403, detail="비공개 또는 멤버십 전용 영상입니다")
            raise HTTPException(status_code=500, detail="YouTube 오디오 추출 실패. URL을 확인해주세요.")

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
        "반드시 아래 JSON 형식만 반환하고 추가 설명은 쓰지 마세요."
    )

    user_prompt = f"""다음 설교 텍스트를 분석하여 JSON으로만 응답해주세요:

{truncated}

응답 형식 (JSON만, 한국어로):
{{
  "summary": "[전체 요약] 설교의 배경·핵심 주제·주요 논증·결론을 논리적 흐름으로 3~4개의 긴 문단(총 10~15줄)으로 풍성하게 풀어쓸 것. 신학적 깊이와 평신도 이해를 함께 고려. 그 다음 줄을 띄운 후 [핵심 교훈] 제목 아래 설교의 가장 중요한 포인트 3~4가지를 '- 제목\\n내용' 형태의 글머리 기호로 각각 2~3문장씩 상세하게 작성할 것.",
  "day1": "월요일 - 오늘 말씀에서 깨달은 핵심 진리를 3~4문장으로 풍성하게",
  "day2": "화요일 - 이 말씀을 내 삶에 적용하는 구체적인 방법을 3~4문장으로",
  "day3": "수요일 - 이 말씀에 근거한 기도 제목과 기도문을 3~4문장으로",
  "day4": "목요일 - 이번 주 실천할 구체적인 한 가지 행동을 3~4문장으로",
  "day5": "금요일 - 구역/셀 모임에서 함께 나눌 핵심 질문과 적용을 3~4문장으로"
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
    server_key: str


def _verify_server_key(key: str):
    expected = os.getenv("NOTIFY_SERVER_KEY")
    if not expected or key != expected:
        raise HTTPException(status_code=403, detail="인증 실패")


@app.post("/notify/topic")
async def notify_topic(req: NotifyTopicRequest):
    """토픽 구독자 전체에게 푸시 알림 발송 (관리자 전용)"""
    _verify_server_key(req.server_key)
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
async def notify_token(req: NotifyTokenRequest):
    """특정 FCM 토큰으로 개인 알림 발송 (목사님 목양 알림용)"""
    _verify_server_key(req.server_key)
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
