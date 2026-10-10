# ストア用のスクリーンショットを作る
#   python3 marketing/make_store_shots.py <iPhoneの画面写真フォルダ> <iPadの画面写真フォルダ> <出力先>
# 画面写真は integration_test(SCREENS_DIR を指定)と、-widgetPreview の確認画面で撮る
import sys, os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

PHONE, PAD, OUT = sys.argv[1], sys.argv[2], sys.argv[3]
BOLD = "/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc"
REG = "/System/Library/Fonts/ヒラギノ角ゴシック W3.ttc"
BG, FG, SUB, ACCENT = (244, 231, 220), (44, 37, 32), (122, 112, 104), (184, 120, 78)

SHOTS = [
    ("s01_family", "親と、これから\n会える回数", "家族と過ごせる時間が、家族ごとにわかる", 0),
    ("s05_home", "ホーム画面で\n次に会う日を数える", "アプリを開かなくても、毎日目に入る", 0),
    ("s04_detail", "会えた日も、話した日も\nワンタップで残す", "会えた日は、写真とひとことで", 0),
    ("s02_records", "つながった日が\n積み重なる", "会えた・話した・メッセージ", 0),
    ("s03_review", "1年を、家族ごとに\nふりかえる", "写真を並べた1枚にして、家族に送れる", 0),
]

def make(src_dir, size, out_dir, shots):
    W, H = size
    os.makedirs(out_dir, exist_ok=True)
    for i, (name, head, sub, crop_top) in enumerate(shots, 1):
        path = os.path.join(src_dir, f"{name}.png")
        if not os.path.exists(path):
            print("skip", path); continue
        img = Image.new("RGB", (W, H), BG)
        d = ImageDraw.Draw(img)
        hs = int(W * 0.068)
        f_head, f_sub = ImageFont.truetype(BOLD, hs), ImageFont.truetype(REG, int(hs * 0.42))
        top = int(H * 0.06)
        d.multiline_text((W / 2, top), head, font=f_head, fill=FG, anchor="ma", align="center", spacing=int(hs * 0.3))
        hb = d.multiline_textbbox((W / 2, top), head, font=f_head, anchor="ma", align="center", spacing=int(hs * 0.3))
        d.text((W / 2, hb[3] + int(hs * 0.5)), sub, font=f_sub, fill=SUB, anchor="ma")
        shot = Image.open(path).convert("RGB")
        if crop_top:
            shot = shot.crop((0, crop_top, shot.width, shot.height))
        sw = int(W * 0.80)
        sh = int(shot.height * sw / shot.width)
        shot = shot.resize((sw, sh), Image.LANCZOS)
        y = hb[3] + int(hs * 1.6)
        r = int(sw * 0.07)
        mask = Image.new("L", (sw, sh), 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, sw, sh), radius=r, fill=255)
        shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        ImageDraw.Draw(shadow).rounded_rectangle(((W - sw) // 2, y + 18, (W + sw) // 2, y + sh + 18), radius=r, fill=(80, 50, 30, 70))
        shadow = shadow.filter(ImageFilter.GaussianBlur(30))
        img.paste(shadow, (0, 0), shadow)
        img.paste(shot, ((W - sw) // 2, y), mask)
        img.save(os.path.join(out_dir, f"{i:02d}_{name}.png"))
    print("done", out_dir)

make(PHONE, (1320, 2868), os.path.join(OUT, "iphone_6_9"), SHOTS)
make(PAD, (2064, 2752), os.path.join(OUT, "ipad_13"), [x for x in SHOTS if x[0] != "s05_home"])
