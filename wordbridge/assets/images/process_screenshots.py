"""
말씀브릿지 스크린샷 처리
- Android 상태바(상단 40px) 제거
- iPhone 6.9형: 1290×2796
- iPad 12.9형: 2048×2732
"""

from PIL import Image, ImageFilter
import os

SRC_DIR = os.path.dirname(os.path.abspath(__file__))
OUT_DIR = os.path.join(SRC_DIR, "appstore")
os.makedirs(os.path.join(OUT_DIR, "iphone"), exist_ok=True)
os.makedirs(os.path.join(OUT_DIR, "ipad"), exist_ok=True)

STATUS_BAR_HEIGHT = 40  # Android 상태바 크롭 높이 (px)

IPHONE_W, IPHONE_H = 1290, 2796  # iPhone 6.9형 (iPhone 16 Pro Max)
IPAD_W, IPAD_H = 2048, 2732      # iPad 12.9형

BG_COLOR = (248, 248, 248)  # 앱 배경색 #F8F8F8

files = sorted([
    f for f in os.listdir(SRC_DIR)
    if f.startswith("KakaoTalk") and f.endswith(".jpg")
])

print(f"처리할 파일: {len(files)}장\n")

for idx, fname in enumerate(files, 1):
    src_path = os.path.join(SRC_DIR, fname)
    img = Image.open(src_path).convert("RGB")
    w, h = img.size
    print(f"[{idx}] {fname} ({w}×{h})")

    # 1. 상태바 제거
    cropped = img.crop((0, STATUS_BAR_HEIGHT, w, h))
    cw, ch = cropped.size
    print(f"    크롭 후: {cw}×{ch}")

    # ── iPhone 처리 ──
    # 높이 기준 스케일 → 너비 중앙 크롭
    scale = IPHONE_H / ch
    new_w = round(cw * scale)
    resized = cropped.resize((new_w, IPHONE_H), Image.LANCZOS)
    if new_w >= IPHONE_W:
        # 너비가 크면 중앙 크롭
        left = (new_w - IPHONE_W) // 2
        iphone_img = resized.crop((left, 0, left + IPHONE_W, IPHONE_H))
    else:
        # 너비가 작으면 배경에 중앙 배치
        iphone_img = Image.new("RGB", (IPHONE_W, IPHONE_H), BG_COLOR)
        offset_x = (IPHONE_W - new_w) // 2
        iphone_img.paste(resized, (offset_x, 0))

    iphone_path = os.path.join(OUT_DIR, "iphone", f"screenshot_{idx:02d}.jpg")
    iphone_img.save(iphone_path, "JPEG", quality=95)
    print(f"    iPhone 저장: {iphone_path} ({iphone_img.size[0]}×{iphone_img.size[1]})")

    # ── iPad 처리 ──
    # 높이 기준 스케일 → 좌우 배경 패딩
    scale_ipad = IPAD_H / ch
    new_w_ipad = round(cw * scale_ipad)
    resized_ipad = cropped.resize((new_w_ipad, IPAD_H), Image.LANCZOS)

    if new_w_ipad >= IPAD_W:
        left = (new_w_ipad - IPAD_W) // 2
        ipad_img = resized_ipad.crop((left, 0, left + IPAD_W, IPAD_H))
    else:
        # 배경: 원본 이미지를 블러해서 배경으로 사용 (자연스러운 패딩)
        bg_scale = IPAD_H / ch
        bg_w = max(IPAD_W, round(cw * bg_scale * 2))
        bg_resized = cropped.resize((bg_w, IPAD_H), Image.LANCZOS)
        bg_blurred = bg_resized.filter(ImageFilter.GaussianBlur(radius=30))
        bg_left = (bg_w - IPAD_W) // 2
        ipad_bg = bg_blurred.crop((bg_left, 0, bg_left + IPAD_W, IPAD_H))

        # 배경 위에 콘텐츠 이미지 중앙 배치
        offset_x = (IPAD_W - new_w_ipad) // 2
        ipad_img = ipad_bg.copy()
        ipad_img.paste(resized_ipad, (offset_x, 0))

    ipad_path = os.path.join(OUT_DIR, "ipad", f"screenshot_{idx:02d}.jpg")
    ipad_img.save(ipad_path, "JPEG", quality=95)
    print(f"    iPad  저장: {ipad_path} ({ipad_img.size[0]}×{ipad_img.size[1]})")
    print()

print("완료!")
