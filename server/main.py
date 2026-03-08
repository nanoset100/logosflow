import os
import tempfile
import asyncio
from pathlib import Path
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
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

app = FastAPI(title="Chimshin Whisper Server", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


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


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    uvicorn.run("main:app", host="0.0.0.0", port=port)
