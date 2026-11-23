"""Draw the Rounds Companion app icon (original flat geometric art). Needs Pillow.

Usage: python tools/make_icon.py ios/RoundsCompanion/Assets.xcassets/AppIcon.appiconset/AppIcon.png
"""
import sys
from PIL import Image, ImageDraw

out = sys.argv[1]
S = 1024 * 4  # supersample, then downscale for smooth edges
img = Image.new("RGB", (S, S), (16, 74, 52))
d = ImageDraw.Draw(img)

# Putting green: a wide ellipse in the lower half.
d.ellipse([int(S * 0.14), int(S * 0.62), int(S * 0.86), int(S * 0.86)], fill=(62, 160, 98))
# Cup.
d.ellipse([int(S * 0.44), int(S * 0.715), int(S * 0.56), int(S * 0.765)], fill=(10, 40, 28))
# Pin.
d.rectangle([int(S * 0.488), int(S * 0.17), int(S * 0.512), int(S * 0.74)], fill=(245, 245, 240))
# Flag: a pennant to the right of the pin.
d.polygon(
    [(int(S * 0.512), int(S * 0.17)), (int(S * 0.78), int(S * 0.255)), (int(S * 0.512), int(S * 0.34))],
    fill=(242, 196, 64),
)

img = img.resize((1024, 1024), Image.LANCZOS).convert("RGB")
img.save(out, "PNG")
print(out, img.size, img.mode)
