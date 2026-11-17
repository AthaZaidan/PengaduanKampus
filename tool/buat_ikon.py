#!/usr/bin/env python3
"""Membuat seluruh ikon aplikasi & aset splash dari geometri logo_tile.svg /
logo_glyph_white.svg (viewBox 130x130).

Jalankan dari akar proyek:  python3 tool/buat_ikon.py   (butuh Pillow)
"""
import json, os
from PIL import Image, ImageDraw

HIJAU = (0x3F, 0x6E, 0x4B, 255)
PUTIH = (255, 255, 255, 255)
SAGE = (0xE3, 0xEE, 0xDF, 255)
SS = 4  # supersampling untuk tepi halus

# Kotak pembatas glyph (tanpa latar) pada viewBox 130: x 30..115, y 26..113.
GLYPH_PUSAT = (72.5, 69.5)


def gambar(d, s, tx, ty):
    """Menggambar glyph; titik (x, y) -> (x*s+tx, y*s+ty)."""
    p = lambda x, y: (x * s + tx, y * s + ty)
    d.polygon([p(65, 26), p(100, 44), p(30, 44)], fill=PUTIH)
    for x, y, w, h in [(32, 47, 66, 5), (38, 55, 10, 33), (60, 55, 10, 33),
                       (82, 55, 10, 33), (30, 90, 70, 6)]:
        d.rectangle([p(x, y), p(x + w, y + h)], fill=PUTIH)
    cx, cy = p(94, 92)
    d.ellipse([cx - 21 * s, cy - 21 * s, cx + 21 * s, cy + 21 * s], fill=HIJAU)
    d.ellipse([cx - 17 * s, cy - 17 * s, cx + 17 * s, cy + 17 * s], fill=SAGE)
    cek = [p(85, 92), p(91, 98), p(103, 85)]
    w = 4.5 * s
    d.line(cek, fill=HIJAU, width=round(w), joint='curve')
    for x, y in cek:
        d.ellipse([x - w / 2, y - w / 2, x + w / 2, y + w / 2], fill=HIJAU)


def render(ukuran, *, latar='bulat', skala_isi=1.0, pusat=(65, 65), isi_lebar=None):
    """latar: 'bulat' (rx 28), 'penuh' (persegi), None (transparan).
    skala_isi mengecilkan isi terhadap pusat kanvas; isi_lebar (opsional)
    memusatkan glyph pada GLYPH_PUSAT dengan lebar kotak tertentu (fraksi)."""
    n = ukuran * SS
    img = Image.new('RGBA', (n, n), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    k = n / 130
    if latar == 'bulat':
        d.rounded_rectangle([0, 0, n - 1, n - 1], radius=28 * k, fill=HIJAU)
    elif latar == 'penuh':
        d.rectangle([0, 0, n, n], fill=HIJAU)
    if isi_lebar:
        s = isi_lebar * n / 85
        tx, ty = n / 2 - GLYPH_PUSAT[0] * s, n / 2 - GLYPH_PUSAT[1] * s
    else:
        s = k * skala_isi
        tx, ty = n / 2 - pusat[0] * s, n / 2 - pusat[1] * s
    gambar(d, s, tx, ty)
    return img.resize((ukuran, ukuran), Image.LANCZOS)


def simpan(img, path, rgb=False):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if rgb:
        bg = Image.new('RGB', img.size, HIJAU[:3])
        bg.paste(img, mask=img.split()[3])
        img = bg
    img.save(path)


def main():
    # Android: ikon lawas (bulat).
    for dens, u in {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}.items():
        simpan(render(u), f'android/app/src/main/res/mipmap-{dens}/ic_launcher.png')
    # Android: logo di layar splash native (glyph terpusat, tinggi 96dp).
    for dens, u in {'mdpi': 96, 'hdpi': 144, 'xhdpi': 192, 'xxhdpi': 288, 'xxxhdpi': 384}.items():
        simpan(render(u, latar=None, isi_lebar=0.88),
               f'android/app/src/main/res/drawable-{dens}/splash_logo.png')
    # iOS (persegi penuh tanpa alpha) & macOS (bulat, transparan).
    for platform in ('ios', 'macos'):
        dir_ = f'{platform}/Runner/Assets.xcassets/AppIcon.appiconset'
        data = json.load(open(f'{dir_}/Contents.json'))
        for it in data['images']:
            if not it.get('filename'):
                continue
            u = round(float(it['size'].split('x')[0]) * float(it['scale'].replace('x', '')))
            if platform == 'ios':
                simpan(render(u, latar='penuh'), f'{dir_}/{it["filename"]}', rgb=True)
            else:
                simpan(render(u), f'{dir_}/{it["filename"]}')
    # Windows.
    ico = render(256)
    os.makedirs('windows/runner/resources', exist_ok=True)
    ico.save('windows/runner/resources/app_icon.ico',
             sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
    # Web.
    for u in (192, 512):
        simpan(render(u), f'web/icons/Icon-{u}.png')
        simpan(render(u, latar='penuh', skala_isi=0.8), f'web/icons/Icon-maskable-{u}.png')
    simpan(render(32), 'web/favicon.png')
    # Aset Flutter (layar splash, halaman login, dll).
    simpan(render(512), 'assets/branding/logo_tile.png')
    simpan(render(512, latar=None, isi_lebar=0.88), 'assets/branding/logo_glyph_white.png')
    simpan(render(1024, latar='penuh'), 'assets/branding/ikon-kampus.png')


if __name__ == '__main__':
    main()
