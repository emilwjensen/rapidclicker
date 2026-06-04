#!/usr/bin/env python3
"""Generate a branded DMG background (1x + @2x) for RapidClicker."""
import os
from PIL import Image, ImageDraw, ImageFont

ICON = "RapidClicker/Assets.xcassets/AppIcon.appiconset/1024-mac.png"
OUT = "build/dmgassets"
os.makedirs(OUT, exist_ok=True)

W, H = 640, 420  # window content size in points

def font(paths, size):
    for p in paths:
        try:
            return ImageFont.truetype(p, size)
        except Exception:
            continue
    return ImageFont.load_default()

BOLD = ["/System/Library/Fonts/SFNSRounded.ttf",
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf"]
REG = ["/System/Library/Fonts/SFNSRounded.ttf",
       "/System/Library/Fonts/SFNS.ttf",
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
    c_br = (196, 36, 216)

def gradient(w, h):
    gw, gh = 90, 60
    g = Image.new("RGB", (gw, gh))
    for j in range(gh):
        for i in range(gw):
            t = (i / (gw - 1) + j / (gh - 1)) / 2
            g.putpixel((i, j), lerp(c_tl, c_br, t))
    return g.resize((w, h), Image.BICUBIC)

def render(s):
    img = gradient(W * s, H * s).convert("RGB")
    d = ImageDraw.Draw(img, "RGBA")

    f_title = font(BOLD, 34 * s)
    f_caption = font(REG, 17 * s)
    f_footer = font(REG, 16 * s)

    # --- soft drop shadow + white install card ---
    card = [60 * s, 150 * s, 580 * s, 312 * s]
    shadow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle([card[0], card[1] + 6 * s, card[2], card[3] + 6 * s],
                         radius=28 * s, fill=(20, 10, 40, 90))
    from PIL import ImageFilter
    shadow = shadow.filter(ImageFilter.GaussianBlur(10 * s))
    img.paste(shadow, (0, 0), shadow)
    d.rounded_rectangle(card, radius=28 * s, fill=(255, 255, 255, 235))

    # --- header: icon + title, centered ---
    ic = 46 * s
    thumb = icon.resize((ic, ic), Image.LANCZOS)
    title = "RapidClicker"
    tw = d.textlength(title, font=f_title)
    gap = 12 * s
    total = ic + gap + tw
    x0 = (W * s - total) / 2
    cy = 56 * s
    img.paste(thumb, (int(x0), int(cy - ic / 2)), thumb)
    d.text((x0 + ic + gap, cy), title, font=f_title, fill=(255, 255, 255, 255), anchor="lm")

    # --- caption + arrow between the two icon slots ---
    d.text((320 * s, 184 * s), "Drag to install", font=f_caption,
           fill=(70, 70, 90, 255), anchor="mm")
    ax0, ax1, ay = 256 * s, 384 * s, 224 * s
    arrow_col = (c_br[0], c_br[1], c_br[2], 255)
    d.line([(ax0, ay), (ax1 - 10 * s, ay)], fill=arrow_col, width=4 * s)
    d.polygon([(ax1, ay), (ax1 - 16 * s, ay - 9 * s), (ax1 - 16 * s, ay + 9 * s)],
              fill=arrow_col)

    # --- footer ---
    d.text((320 * s, 392 * s), "built by EWJ", font=f_footer,
           fill=(255, 255, 255, 220), anchor="mm")

    return img

render(1).save(f"{OUT}/background.png")
render(2).save(f"{OUT}/background@2x.png")
print("gradient", c_tl, "->", c_br)
print("wrote", OUT + "/background.png (640x420) and @2x (1280x840)")
