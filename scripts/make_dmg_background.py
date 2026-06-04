#!/usr/bin/env python3
"""Render a premium DMG background for RapidClicker at 1x and 2x (Retina).

Outputs build/dmgassets/background.png and background@2x.png. The DMG build
script combines them into a HiDPI .tiff so text stays crisp on Retina displays.
"""
import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ICON = "RapidClicker/Assets.xcassets/AppIcon.appiconset/1024-mac.png"
OUT = "build/dmgassets"
os.makedirs(OUT, exist_ok=True)

W, H = 680, 446  # window content size in points

def font(paths, size):
    for p in paths:
        try:
            return ImageFont.truetype(p, size)
        except Exception:
            continue
    return ImageFont.load_default()

ROUND = ["/System/Library/Fonts/SFNSRounded.ttf",
         "/System/Library/Fonts/SFCompactRounded.ttf",
         "/System/Library/Fonts/Supplemental/Arial Bold.ttf"]
REG = ["/System/Library/Fonts/SFNS.ttf",
       "/System/Library/Fonts/Supplemental/Arial.ttf"]

def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))

icon = Image.open(ICON).convert("RGBA")
iw, ih = icon.size

def sample(fx, fy):
    return icon.getpixel((int(iw * fx), int(ih * fy)))[:3]

c_tl = sample(0.34, 0.30)
c_br = sample(0.70, 0.74)
if min(c_tl) > 205:
    c_tl = (78, 96, 240)
if min(c_br) > 205:
    c_br = (206, 31, 240)

def gradient(w, h):
    gw, gh = 200, 132
    g = Image.new("RGB", (gw, gh))
    px = g.load()
    for j in range(gh):
        for i in range(gw):
            t = (i / (gw - 1) + j / (gh - 1)) / 2
            px[i, j] = lerp(c_tl, c_br, t)
    return g.resize((w, h), Image.BICUBIC)

def render(s):
    img = gradient(W * s, H * s).convert("RGB")

    # subtle top highlight for depth
    glow = Image.new("L", (W * s, H * s), 0)
    gd = ImageDraw.Draw(glow)
    gd.ellipse([W * s * 0.18, -H * s * 0.55, W * s * 0.82, H * s * 0.45], fill=70)
    glow = glow.filter(ImageFilter.GaussianBlur(60 * s))
    white = Image.new("RGB", img.size, (255, 255, 255))
    img = Image.composite(white, img, glow.point(lambda v: int(v * 0.5)))

    d = ImageDraw.Draw(img, "RGBA")
    f_title = font(ROUND, 40 * s)
    f_tag = font(REG, 16 * s)
    f_caption = font(ROUND, 18 * s)
    f_footer = font(REG, 15 * s)

    # --- install card: soft shadow + vertical-gradient white panel ---
    card = (48 * s, 168 * s, 632 * s, 364 * s)
    radius = 36 * s
    shadow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle([card[0], card[1] + 10 * s, card[2], card[3] + 10 * s],
                         radius=radius, fill=(15, 6, 35, 95))
    shadow = shadow.filter(ImageFilter.GaussianBlur(16 * s))
    img.paste(shadow, (0, 0), shadow)

    cw, ch = int(card[2] - card[0]), int(card[3] - card[1])
    panel = Image.new("RGB", (cw, ch))
    pp = panel.load()
    for y in range(ch):
        col = lerp((255, 255, 255), (246, 246, 250), y / max(ch - 1, 1))
        for x in range(cw):
            pp[x, y] = col
    mask = Image.new("L", (cw, ch), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, cw - 1, ch - 1], radius=radius, fill=255)
    img.paste(panel, (int(card[0]), int(card[1])), mask)

    d = ImageDraw.Draw(img, "RGBA")

    # --- title wordmark (no icon) + tagline ---
    d.text((W * s / 2, 72 * s), "RapidClicker", font=f_title,
           fill=(255, 255, 255, 255), anchor="mm")
    d.text((W * s / 2, 108 * s), "Simple macOS auto-clicker", font=f_tag,
           fill=(255, 255, 255, 180), anchor="mm")

    # --- caption + arrow in the gap between the icon slots ---
    d.text((340 * s, 214 * s), "Drag to install", font=f_caption,
           fill=(64, 66, 86, 255), anchor="mm")
    ay = 254 * s
    ax0, ax1 = 282 * s, 402 * s
    col = (c_br[0], c_br[1], c_br[2], 255)
    d.line([(ax0, ay), (ax1 - 12 * s, ay)], fill=col, width=5 * s)
    r = int(2.5 * s)
    d.ellipse([ax0 - r, ay - r, ax0 + r, ay + r], fill=col)
    d.polygon([(ax1, ay), (ax1 - 18 * s, ay - 10 * s), (ax1 - 18 * s, ay + 10 * s)], fill=col)

    # --- footer ---
    d.text((W * s / 2, 410 * s), "built by EWJ", font=f_footer,
           fill=(255, 255, 255, 195), anchor="mm")

    return img

render(1).save(f"{OUT}/background.png")
render(2).save(f"{OUT}/background@2x.png")
print("gradient", c_tl, "->", c_br)
print(f"wrote {OUT}/background.png ({W}x{H}) and @2x ({W*2}x{H*2})")
