"""Şipşak ikonlarını üretir: sarı zemin üstünde siyah şimşek (uygulama ikonu)
ve beyaz şimşek (bildirim ikonu). Çıktılar tool/res/ altına yazılır."""
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent / "res"
FLASH = (255, 210, 63, 255)
INK = (14, 14, 16, 255)

# 24x24 tasarım ızgarasında şimşek
BOLT = [(13, 2), (4, 14), (11, 14), (10, 22), (19, 10), (12, 10), (13, 2)]


def bolt(size, box, color, draw):
    x0, y0, s = box
    pts = [(x0 + px / 24 * s, y0 + py / 24 * s) for px, py in BOLT]
    draw.polygon(pts, fill=color)


def launcher(px):
    scale = 8
    big = px * scale
    img = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, big - 1, big - 1], radius=int(big * 0.24), fill=FLASH)
    s = big * 0.72
    bolt(big, ((big - s) / 2, (big - s) / 2, s), INK, d)
    return img.resize((px, px), Image.LANCZOS)


def round_launcher(px):
    scale = 8
    big = px * scale
    img = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([0, 0, big - 1, big - 1], fill=FLASH)
    s = big * 0.66
    bolt(big, ((big - s) / 2, (big - s) / 2, s), INK, d)
    return img.resize((px, px), Image.LANCZOS)


def notif(px):
    scale = 8
    big = px * scale
    img = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    s = big * 0.95
    bolt(big, ((big - s) / 2, (big - s) / 2, s), (255, 255, 255, 255), d)
    return img.resize((px, px), Image.LANCZOS)


DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}

for name, k in DENSITIES.items():
    m = ROOT / f"mipmap-{name}"
    m.mkdir(parents=True, exist_ok=True)
    launcher(int(48 * k)).save(m / "ic_launcher.png")
    round_launcher(int(48 * k)).save(m / "ic_launcher_round.png")
    dr = ROOT / f"drawable-{name}"
    dr.mkdir(parents=True, exist_ok=True)
    notif(int(24 * k)).save(dr / "ic_stat_sipsak.png")

launcher(512).save(ROOT.parent / "icon_512.png")
print("ikonlar hazır:", ROOT)
