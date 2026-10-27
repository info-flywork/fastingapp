"""Ada görselinin pastel gökyüzünü kasvetli, yağmurlu griye çevirir (ada aynı kalır).
Kullanım: python3 asset_sources/mochi/rainify_base.py asset_sources/images/mochi-world-rain.png
"""
import sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

SRC = '/Users/flywork/Projects/fastingapp/asset_sources/images/mochi-world-5.png'
im = Image.open(SRC).convert('RGB')
a = np.array(im).astype(float)
H, W = a.shape[:2]
hsv = np.array(im.convert('HSV')).astype(int)
h, s, v = hsv[..., 0], hsv[..., 1], hsv[..., 2]

# Gökyüzü: düşük doygunluklu bulutlar ya da mavi tonlar, kenara bağlı olanlar.
skyish = (v > 185) & ((s < 60) | ((h > 115) & (h < 205)))
mask = Image.fromarray((skyish * 255).astype('uint8'))
mask = mask.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.MaxFilter(3))
for x in range(0, W, 8):
    for y in (0, H - 1):
        if mask.getpixel((x, y)) == 255:
            ImageDraw.floodfill(mask, (x, y), 128)
for y in range(0, H, 8):
    for x in (0, W - 1):
        if mask.getpixel((x, y)) == 255:
            ImageDraw.floodfill(mask, (x, y), 128)
core = np.array(mask) == 128
sky = core.copy()
# Ada kenarındaki açık mavi/beyaz hale: gökyüzüne komşu soluk pikseller de.
near = np.array(Image.fromarray(sky.astype('uint8') * 255).filter(ImageFilter.MaxFilter(7))) > 0
sky |= near & ((s < 70) | ((h > 115) & (h < 205))) & (v > 120)
sky = sky.astype('uint8') * 255
m = np.array(Image.fromarray(sky).filter(ImageFilter.GaussianBlur(1.5))).astype(float)[..., None] / 255

lum = (0.3 * a[..., 0] + 0.55 * a[..., 1] + 0.15 * a[..., 2]) / 255
t = ((lum - 0.55) / 0.40).clip(0, 1) ** 1.1
dark = np.array([62, 70, 82.])
light = np.array([170, 178, 188.])
storm = dark + (light - dark) * t[..., None]
# Tepe daha koyu, alt hafif sisli.
yy = (np.arange(H) / H)[:, None, None]
storm *= 0.82 + 0.22 * yy
# Kenar halesi kendi parlaklığıyla değil, komşu gökyüzünün rengiyle dolar.
def blur(x, r=6):
    for axis in (0, 1):
        for _ in range(2):  # iki kez kutu bulanıklığı ≈ yumuşak çan
            c = np.cumsum(np.pad(x, [(r + 1, r) if i == axis else (0, 0) for i in range(x.ndim)], mode='edge'), axis=axis)
            x = (np.take(c, range(2 * r + 1, c.shape[axis]), axis=axis) - np.take(c, range(0, c.shape[axis] - 2 * r - 1), axis=axis)) / (2 * r + 1)
    return x
cf = core[..., None].astype(float)
fill = blur(storm * cf) / np.maximum(blur(np.repeat(cf, 3, -1)), 1e-3)
fringe = ((sky > 0) & ~core)[..., None]
storm = np.where(fringe, fill, storm)
out = a * (1 - m) + storm.clip(0, 255) * m
Image.fromarray(out.clip(0, 255).astype('uint8')).save(sys.argv[1])
