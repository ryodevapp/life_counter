import sys
# 比較画像を作る: python3 marketing/make_compare.py build/screens marketing/images
# (先に integration_test で画面写真を build/screens に撮っておく)
from PIL import Image, ImageDraw, ImageFont
SCREENS, OUT = sys.argv[1], sys.argv[2]
FONT = "/System/Library/Fonts/ヒラギノ角ゴシック W3.ttc"
BOLD = "/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc"
BG, FG, MUTED, ACCENT, PANEL = (253,251,247), (44,37,32), (122,112,104), (184,120,78), (244,231,220)

VARIANTS = {
  "A": ("LifeCounter - 家族と過ごせる時間", "親に会える回数、子どもと過ごす時間", [
      ("13_family_list", "親と会えるのは、\nこれから約43回"),
      ("15_detail", "会えた日が、\nひとつずつ積み重なる"),
      ("03_step2", "限られた時間を、\nやさしく大切に"),
  ]),
  "B": ("LifeCounter - 人生の日数と毎日の日記", "今日は人生何日目?1日を大切にする習慣", [
      ("03_step1", "今日は、\n人生何日目?"),
      ("2x_tab_記録", "朝と夜の問いかけを、\n日記に残す"),
      ("2x_tab_人生", "これからの時間を、\n大切に"),
  ]),
}
W = 1170
for key, (name, sub, shots) in VARIANTS.items():
    img = Image.new("RGB", (W, 1500), BG)
    d = ImageDraw.Draw(img)
    f_name, f_sub, f_cap, f_tag = (ImageFont.truetype(BOLD, 40), ImageFont.truetype(FONT, 30),
                                   ImageFont.truetype(BOLD, 27), ImageFont.truetype(BOLD, 28))
    d.text((60, 40), f"案 {key}", font=f_tag, fill=ACCENT)
    # アイコンと名前(検索結果の1行)
    d.rounded_rectangle((60, 100, 200, 240), radius=32, fill=(212,165,116))
    d.ellipse((108, 148, 152, 192), fill=BG)
    d.text((230, 120), name, font=f_name, fill=FG)
    d.text((230, 180), sub, font=f_sub, fill=MUTED)
    # スクリーンショット3枚
    tw, gap, top = 330, 40, 300
    for i, (file, cap) in enumerate(shots):
        x = 60 + i * (tw + gap)
        sh0 = int(1334 * (tw - 50) / 750)
        d.rounded_rectangle((x, top, x + tw, top + 150 + sh0 + 30), radius=36, fill=PANEL)
        d.multiline_text((x + tw / 2, top + 40), cap, font=f_cap, fill=FG, anchor="ma", align="center", spacing=12)
        shot = Image.open(f"{SCREENS}/{file}.png").convert("RGB")
        sw = tw - 50
        sh = int(shot.height * sw / shot.width)
        shot = shot.resize((sw, sh))
        mask = Image.new("L", shot.size, 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, sw, sh), radius=24, fill=255)
        img.paste(shot, (x + 25, top + 150), mask)
    img = img.crop((0, 0, W, top + 150 + int(1334 * (tw - 50) / 750) + 70))
    img.save(f"{OUT}/compare_{key}.png")
print("ok")
