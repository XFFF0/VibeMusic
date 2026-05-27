#!/usr/bin/env python3
"""
Generates a green Vibe Music app icon (1024x1024 PNG) using Pillow.
Run: pip install Pillow && python3 generate_icon.py
"""
import math
from PIL import Image, ImageDraw, ImageFilter
import os

SIZE = 1024
OUT = "Sources/VibeMusic/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"

def draw_icon():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Background – deep dark green
    cx, cy = SIZE // 2, SIZE // 2
    draw.rounded_rectangle([0, 0, SIZE, SIZE], radius=230,
                           fill=(10, 15, 10, 255))

    # Radial glow
    glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    for r in range(380, 0, -2):
        alpha = int(80 * (1 - r / 380))
        gd.ellipse([cx - r, cy - r, cx + r, cy + r],
                   fill=(46, 235, 112, alpha))
    glow = glow.filter(ImageFilter.GaussianBlur(40))
    img = Image.alpha_composite(img, glow)
    draw = ImageDraw.Draw(img)

    # Waveform bars
    bar_count = 7
    bar_w = 56
    gap = 22
    total_w = bar_count * bar_w + (bar_count - 1) * gap
    heights = [180, 300, 420, 520, 420, 300, 180]
    start_x = cx - total_w // 2

    for i, h in enumerate(heights):
        x0 = start_x + i * (bar_w + gap)
        x1 = x0 + bar_w
        y0 = cy - h // 2
        y1 = cy + h // 2
        r = bar_w // 2

        # Shadow / glow layer
        for blur in [60, 40, 20]:
            s = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
            sd = ImageDraw.Draw(s)
            sd.rounded_rectangle([x0 - blur//3, y0 - blur//3,
                                   x1 + blur//3, y1 + blur//3],
                                  radius=r + blur//3,
                                  fill=(46, 235, 112, 30))
            s = s.filter(ImageFilter.GaussianBlur(blur // 2))
            img = Image.alpha_composite(img, s)

        draw = ImageDraw.Draw(img)

        # Liquid glass gradient pill
        for row in range(y0, y1):
            t = (row - y0) / (y1 - y0)
            g = int(46 + (235 - 46) * (1 - t))
            b = int(112 + (180 - 112) * (1 - t))
            alpha = 255 if 0.1 < t < 0.9 else int(255 * (1 - abs(t - 0.5) * 2.5))
            draw.line([(x0, row), (x1, row)], fill=(46, g, b, max(0, min(255, alpha))))

        # Specular highlight
        draw.rounded_rectangle([x0 + 6, y0 + 10, x0 + bar_w * 0.45, y0 + h * 0.35],
                                radius=bar_w // 4,
                                fill=(255, 255, 255, 55))

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    img.save(OUT, "PNG")
    print(f"Icon saved → {OUT}")

if __name__ == "__main__":
    draw_icon()
