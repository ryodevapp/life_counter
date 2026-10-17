"""Product Hunt のギャラリー(1270x760 の2倍)とサムネイル(240x240)を作る。
使い方: python3 design/store/producthunt/make_gallery.py . design/store/producthunt
"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

repo, out = Path(sys.argv[1]), Path(sys.argv[2])
out.mkdir(parents=True, exist_ok=True)
SHOTS = repo / 'design/store/screenshots/en'
ICON = repo / 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png'

W, H = 2540, 1520
BG = (243, 235, 223)
INK = (38, 30, 26)
SUB = (112, 96, 86)
ACCENT = (154, 95, 56)

SLIDES = [
    (1, 'One question a day', 'Each one comes with a short follow-up', True),
    (3, 'Time with\nyour parents', 'An estimate of how many more\nvisits you may have', False),
    (2, 'Your days,\nin your own words', 'Look back on your moods and answers', False),
    (4, 'A bucket list\nfor your life', 'Keep what you achieve, with the date', False),
    (6, "Today's question\non your home screen", 'Log your mood in one tap,\nor tap Write to answer', False),
]


def font(size, weight):
    f = ImageFont.truetype('/System/Library/Fonts/SFNS.ttf', size)
    # 軸の順は 幅・光学サイズ・GRAD・太さ
    f.set_variation_by_axes([100, 80 if size >= 80 else 28, 400, weight])
    return f


def wrap(draw, text, f, width):
    if '\n' in text:
        return text.split('\n')
    lines, cur = [], ''
    for word in text.split():
        trial = (cur + ' ' + word).strip()
        if draw.textlength(trial, font=f) <= width:
            cur = trial
        else:
            lines.append(cur)
            cur = word
    lines.append(cur)
    return lines


def rounded_icon(size):
    icon = Image.open(ICON).convert('RGBA').resize((size, size), Image.LANCZOS)
    mask = Image.new('L', (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size, size), radius=int(size * 0.225), fill=255)
    icon.putalpha(mask)
    return icon


for i, (shot, title, sub, footer) in enumerate(SLIDES, 1):
    canvas = Image.new('RGB', (W, H), BG)
    draw = ImageDraw.Draw(canvas)

    # 右: ストアのスクリーンショットから端末のカードだけを切り出し、下は画面の外へ流す
    src = Image.open(SHOTS / f'{shot}.png').convert('RGB')
    card = src.crop((60, 420, 1260, src.height))
    scale = 900 / card.width
    card = card.resize((900, int(card.height * scale)), Image.LANCZOS)
    canvas.paste(card, (W - 900 - 170, 120))

    # 左: アプリ名・見出し・小見出し
    x, text_w = 170, 1100
    canvas.paste(rounded_icon(120), (x, 300), rounded_icon(120))
    draw.text((x + 150, 360), 'LifeCounter', font=font(56, 650), fill=INK, anchor='lm')

    y = 540
    tf = font(108, 700)
    for line in wrap(draw, title, tf, text_w):
        draw.text((x, y), line, font=tf, fill=INK)
        y += 132
    y += 30
    sf = font(54, 450)
    for line in wrap(draw, sub, sf, text_w):
        draw.text((x, y), line, font=sf, fill=SUB)
        y += 74

    if footer:
        draw.text((x, H - 200), 'Free, no ads, all on your device', font=font(48, 550), fill=ACCENT)

    canvas.save(out / f'gallery-{i}.png', optimize=True)

thumb = Image.open(ICON).convert('RGB').resize((240, 240), Image.LANCZOS)
thumb.save(out / 'thumbnail-240.png', optimize=True)
print('ok', sorted(p.name for p in out.iterdir()))
