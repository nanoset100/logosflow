"""
침신 말씀노트 - 앱스토어 스크린샷 생성기
Google Play: 1080 x 1920 (9:16)
Apple App Store: 1290 x 2796 (iPhone 6.7")
"""
from PIL import Image, ImageDraw, ImageFont
import os

# ── 설정 ──────────────────────────────────────────────────────────
INPUT_DIR   = r"m:\MyProject777\logosflow\chimshin\assets\images"
OUTPUT_DIR  = r"m:\MyProject777\logosflow\chimshin\assets\store_screenshots"

GOOGLE_SIZE = (1080, 1920)
APPLE_SIZE  = (1290, 2796)

# 침신 브랜드 색상
COLOR_BG_TOP    = (10, 45, 22)     # 진한 숲 초록
COLOR_BG_BTM    = (20, 90, 48)     # 중간 초록
COLOR_WHITE     = (255, 255, 255)
COLOR_LIGHT     = (180, 230, 200)  # 연초록 (서브텍스트)
COLOR_GOLD      = (255, 215, 120)  # 골드 포인트

# 윈도우 한글 폰트 경로 (맑은고딕)
FONT_BOLD_PATH  = "C:/Windows/Fonts/malgunbd.ttf"
FONT_REG_PATH   = "C:/Windows/Fonts/malgun.ttf"

# ── 스크린샷 목록 (파일명, 헤드라인, 서브헤드라인) ──────────────
SCREENSHOTS = [
    (
        "1.jpg",
        "말씀으로 시작하는 하루",
        "설교 · 묵상 · 성경 · 기도를 한 앱에서",
    ),
    (
        "4.jpg",
        "AI가 설교를\n5일 묵상 교재로",
        "구역 예배 교재 자동 생성",
    ),
    (
        "5.jpg",
        "나의 신앙 성장\n기록이 쌓인다",
        "예배 · 묵상 · 성경 · 연속 일수 자동 기록",
    ),
    (
        "6.jpg",
        "설교를 AI 음성으로\n듣는다",
        "남성 · 여성 AI 성우로 설교 요약 낭독",
    ),
    (
        "2.jpg",
        "오늘의 성경과\n나의 기도제목",
        "신약 260장 연간 읽기 + 기도노트",
    ),
]

# ── 헬퍼: 그라디언트 배경 ─────────────────────────────────────────
def make_gradient(size, top_color, btm_color):
    W, H = size
    img = Image.new("RGB", size)
    draw = ImageDraw.Draw(img)
    for y in range(H):
        r = int(top_color[0] + (btm_color[0] - top_color[0]) * y / H)
        g = int(top_color[1] + (btm_color[1] - top_color[1]) * y / H)
        b = int(top_color[2] + (btm_color[2] - top_color[2]) * y / H)
        draw.line([(0, y), (W, y)], fill=(r, g, b))
    return img

# ── 헬퍼: 텍스트 중앙 정렬 ───────────────────────────────────────
def draw_centered_text(draw, text, font, y, canvas_w, color, line_spacing=12):
    lines = text.split("\n")
    total_h = 0
    line_sizes = []
    for line in lines:
        bbox = draw.textbbox((0, 0), line, font=font)
        lw = bbox[2] - bbox[0]
        lh = bbox[3] - bbox[1]
        line_sizes.append((lw, lh))
        total_h += lh + line_spacing
    total_h -= line_spacing

    cur_y = y
    for i, line in enumerate(lines):
        lw, lh = line_sizes[i]
        x = (canvas_w - lw) // 2
        draw.text((x, cur_y), line, font=font, fill=color)
        cur_y += lh + line_spacing
    return cur_y  # 마지막 y 반환

# ── 메인: 단일 스크린샷 생성 ─────────────────────────────────────
def create_store_image(screenshot_path, output_path, headline, sub, target_size):
    W, H = target_size
    scale = W / 1080  # 1290 apple 대응 스케일

    # 배경
    canvas = make_gradient(target_size, COLOR_BG_TOP, COLOR_BG_BTM)

    # 폰트 크기 (스케일 적용)
    sz_headline = int(72 * scale)
    sz_sub      = int(38 * scale)
    sz_badge    = int(28 * scale)

    try:
        font_h  = ImageFont.truetype(FONT_BOLD_PATH, sz_headline)
        font_s  = ImageFont.truetype(FONT_REG_PATH,  sz_sub)
        font_b  = ImageFont.truetype(FONT_REG_PATH,  sz_badge)
    except Exception as e:
        print(f"⚠ 폰트 로드 실패, 기본 폰트 사용: {e}")
        font_h = font_s = font_b = ImageFont.load_default()

    # ── 텍스트 영역 높이 계산 (상단)
    PAD_TOP     = int(90 * scale)
    line_count  = len(headline.split("\n"))
    text_area_h = int((sz_headline * line_count + 30 + sz_sub + 60) * 1.15)

    # ── 폰 프레임 영역
    phone_margin_x = int(60 * scale)
    phone_w        = W - phone_margin_x * 2
    bezel          = int(12 * scale)
    radius         = int(44 * scale)

    # 남은 공간으로 높이 계산 (하단 여백 포함)
    PAD_BOTTOM  = int(80 * scale)
    badge_h     = int(60 * scale)
    phone_h     = H - PAD_TOP - text_area_h - PAD_BOTTOM - badge_h
    phone_x     = phone_margin_x
    phone_y     = PAD_TOP + text_area_h

    # ── 그림자
    shadow_layer = Image.new("RGBA", target_size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow_layer)
    for i in range(20, 0, -1):
        alpha = int(120 * (20 - i) / 20)
        sd.rounded_rectangle(
            [phone_x + i, phone_y + i,
             phone_x + phone_w + i, phone_y + phone_h + i],
            radius=radius, fill=(0, 0, 0, alpha)
        )
    canvas = Image.alpha_composite(canvas.convert("RGBA"), shadow_layer).convert("RGB")

    # ── 폰 베젤 (흰색 테두리)
    draw = ImageDraw.Draw(canvas)
    draw.rounded_rectangle(
        [phone_x, phone_y, phone_x + phone_w, phone_y + phone_h],
        radius=radius, fill=(230, 230, 230)
    )

    # ── 스크린 안쪽
    sx = phone_x + bezel
    sy = phone_y + bezel
    sw = phone_w - bezel * 2
    sh = phone_h - bezel * 2

    screenshot = Image.open(screenshot_path).convert("RGB")
    screenshot = screenshot.resize((sw, sh), Image.Resampling.LANCZOS)

    # 둥근 마스크
    mask = Image.new("L", (sw, sh), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, sw - 1, sh - 1], radius=max(4, radius - bezel), fill=255
    )
    canvas.paste(screenshot, (sx, sy), mask)

    # ── 텍스트 그리기
    draw = ImageDraw.Draw(canvas)

    # 앱 뱃지 (최상단 작은 텍스트)
    badge_text = "✝  침신 말씀노트"
    bbox = draw.textbbox((0, 0), badge_text, font=font_b)
    bw = bbox[2] - bbox[0]
    bh = bbox[3] - bbox[1]
    badge_x = (W - bw - int(32 * scale)) // 2
    badge_y = int(38 * scale)
    draw.rounded_rectangle(
        [badge_x - int(16 * scale), badge_y - int(8 * scale),
         badge_x + bw + int(16 * scale), badge_y + bh + int(8 * scale)],
        radius=int(20 * scale), fill=(255, 255, 255, 30) if False else (30, 100, 60)
    )
    draw.text((badge_x, badge_y), badge_text, font=font_b, fill=COLOR_LIGHT)

    # 헤드라인
    h_y = int(100 * scale)
    end_y = draw_centered_text(draw, headline, font_h, h_y, W, COLOR_WHITE, line_spacing=int(10 * scale))

    # 서브헤드라인
    draw_centered_text(draw, sub, font_s, end_y + int(20 * scale), W, COLOR_LIGHT)

    # 하단 장식선
    line_y = H - PAD_BOTTOM - badge_h // 2
    line_w = int(40 * scale)
    draw.rectangle([W // 2 - line_w, line_y, W // 2 + line_w, line_y + 2],
                   fill=(255, 255, 255, 80) if False else (80, 160, 100))

    # 저장
    canvas.save(output_path, "JPEG", quality=95)
    print(f"OK: {os.path.basename(output_path)}")


# ── 실행 ─────────────────────────────────────────────────────────
if __name__ == "__main__":
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    print("\n[Google Play] 1080 x 1920 ...")
    google_dir = os.path.join(OUTPUT_DIR, "google_play")
    os.makedirs(google_dir, exist_ok=True)
    for i, (fname, headline, sub) in enumerate(SCREENSHOTS, 1):
        create_store_image(
            os.path.join(INPUT_DIR, fname),
            os.path.join(google_dir, f"screenshot_{i:02d}.jpg"),
            headline, sub, GOOGLE_SIZE
        )

    print("\n[Apple App Store] 1290 x 2796 ...")
    apple_dir = os.path.join(OUTPUT_DIR, "apple")
    os.makedirs(apple_dir, exist_ok=True)
    for i, (fname, headline, sub) in enumerate(SCREENSHOTS, 1):
        create_store_image(
            os.path.join(INPUT_DIR, fname),
            os.path.join(apple_dir, f"screenshot_{i:02d}.jpg"),
            headline, sub, APPLE_SIZE
        )

    print(f"\nDone! -> {OUTPUT_DIR}")
    print(f"  google_play/ x {len(SCREENSHOTS)}")
    print(f"  apple/       x {len(SCREENSHOTS)}")
