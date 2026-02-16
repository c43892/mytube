from PIL import Image, ImageDraw, ImageFilter
import os

root = r'C:\works\yt_temp_player\android\app\src\main\res'
size = 1024
img = Image.new('RGBA', (size, size), (0, 0, 0, 0))

bg = Image.new('RGBA', (size, size))
bd = ImageDraw.Draw(bg)
for y in range(size):
    t = y / (size - 1)
    r = int(30 * (1 - t) + 70 * t)
    g = int(90 * (1 - t) + 150 * t)
    b = int(220 * (1 - t) + 255 * t)
    bd.line([(0, y), (size, y)], fill=(r, g, b, 255))

mask = Image.new('L', (size, size), 0)
md = ImageDraw.Draw(mask)
md.rounded_rectangle((40, 40, size - 40, size - 40), radius=220, fill=255)
img.paste(bg, (0, 0), mask)

glow = Image.new('RGBA', (size, size), (255, 255, 255, 0))
gd = ImageDraw.Draw(glow)
gd.ellipse((120, 90, 780, 540), fill=(255, 255, 255, 40))
img = Image.alpha_composite(img, glow)

d = ImageDraw.Draw(img)
d.ellipse((290, 250, 734, 694), fill=(255, 255, 255, 35), outline=(255, 255, 255, 110), width=8)
tri = [(455, 385), (455, 560), (610, 472)]
d.polygon(tri, fill=(255, 255, 255, 235))

d.rounded_rectangle((240, 740, 784, 860), radius=52, fill=(30, 30, 35, 120))
d.text((325, 770), 'MYTUBE', fill=(255, 255, 255, 230))

img = img.filter(ImageFilter.SMOOTH_MORE)

out1024 = r'C:\works\yt_temp_player\assets\icons\mytube_icon_1024.png'
os.makedirs(os.path.dirname(out1024), exist_ok=True)
img.save(out1024)

sizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}
for folder, s in sizes.items():
    p = os.path.join(root, folder, 'ic_launcher.png')
    os.makedirs(os.path.dirname(p), exist_ok=True)
    img.resize((s, s), Image.LANCZOS).save(p)

print('done')
