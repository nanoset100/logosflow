#!/usr/bin/env python3
"""QR 코드 생성 스크립트 - 침신 말씀노트"""

import qrcode
from PIL import Image, ImageDraw, ImageFont
import os

os.makedirs("docs/qr", exist_ok=True)

# 플레이스토어 QR
playstore_url = "https://play.google.com/store/apps/details?id=com.logosflow.chimshin_bible_note"
qr = qrcode.QRCode(version=1, box_size=10, border=4)
qr.add_data(playstore_url)
qr.make(fit=True)
img = qr.make_image(fill_color="black", back_color="white")
img.save("docs/qr/qr_playstore.png")
print("✅ 플레이스토어 QR 생성: docs/qr/qr_playstore.png")

# 앱스토어 QR (심사 통과 후 URL 교체)
appstore_url = "https://apps.apple.com/kr/app/id"  # TODO: 앱스토어 승인 후 ID 입력
qr2 = qrcode.QRCode(version=1, box_size=10, border=4)
qr2.add_data(appstore_url)
qr2.make(fit=True)
img2 = qr2.make_image(fill_color="black", back_color="white")
img2.save("docs/qr/qr_appstore.png")
print("✅ 앱스토어 QR 생성: docs/qr/qr_appstore.png")

print("\n완료! docs/qr/ 폴더에 QR 이미지가 생성됐습니다.")
