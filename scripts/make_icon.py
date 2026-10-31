#!/usr/bin/env python3
"""Generate all Kâmus brand assets from kamus.png (requires Pillow).

Run after replacing the master: python3 scripts/make_icon.py
Action extensions use the extracted alpha mask, never the opaque app tile.
"""
import argparse
import json
import shutil
import subprocess
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
RESOURCES = ROOT / 'Resources'


def save(image, path):
    path = ROOT / path
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)


def mark_mask(master):
    # Both the cream letter and amber accent have red well above blue.
    # The navy background has the opposite relationship. Keep edge coverage.
    red, _, blue = master.split()
    mask = ImageChops.subtract(red, blue).point(lambda v: min(255, v * 8))
    return mask.crop(mask.getbbox())


def centered_mark(mask, size, fraction=0.70):
    mark = mask.copy()
    mark.thumbnail((round(size * fraction), round(size * fraction)), Image.Resampling.LANCZOS)
    alpha = Image.new('L', (size, size))
    alpha.paste(mark, ((size - mark.width) // 2, (size - mark.height) // 2))
    result = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    result.putalpha(alpha)
    return result


def action_icons(mask):
    directory = 'iOS/KamusActionExtension'
    for scale in (1, 2, 3):
        suffix = '' if scale == 1 else f'@{scale}x'
        icon = centered_mark(mask, 60 * scale)
        save(icon, f'{directory}/ActionIcon{suffix}.png')
        if scale > 1:
            save(icon, f'{directory}/Assets.xcassets/AppIcon.appiconset/icon-60@{scale}x.png')
    for size, filename in ((152, 'icon-76@2x.png'), (167, 'icon-83.5@2x.png'), (1024, 'icon-1024.png')):
        save(centered_mark(mask, size), f'{directory}/Assets.xcassets/AppIcon.appiconset/{filename}')
    path = ROOT / directory / 'Assets.xcassets/AppIcon.appiconset/Contents.json'
    contents = json.loads(path.read_text())
    contents['images'] = [
        {'filename': f'icon-60@{scale}x.png', 'idiom': 'iphone', 'scale': f'{scale}x', 'size': '60x60'}
        for scale in (2, 3)
    ] + [
        {'filename': 'icon-76@2x.png', 'idiom': 'ipad', 'scale': '2x', 'size': '76x76'},
        {'filename': 'icon-83.5@2x.png', 'idiom': 'ipad', 'scale': '2x', 'size': '83.5x83.5'},
        {'filename': 'icon-1024.png', 'idiom': 'ios-marketing', 'size': '1024x1024'},
    ]
    path.write_text(json.dumps(contents, indent=2) + '\n')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--action-only', action='store_true')
    args = parser.parse_args()
    master = Image.open(ROOT / 'kamus.png').convert('RGB')
    if master.width != master.height:
        raise ValueError('kamus.png must be square; do not stretch the logo.')
    mask = mark_mask(master)
    action_icons(mask)
    if args.action_only:
        return
    full = master.resize((1024, 1024), Image.Resampling.LANCZOS)
    save(full, 'iOS/Kamus/Assets.xcassets/AppIcon.appiconset/icon-1024.png')
    save(full, 'Resources/AppIcon-fullbleed-v2.png')
    logo = master.resize((192, 192), Image.Resampling.LANCZOS)
    for path in ('Sources/Kamus/Resources/KamusLogo.png', 'android/app/src/main/res/drawable-nodpi/kamus_logo.png'):
        save(logo, path)
    template = centered_mark(mask, 128, 0.84)
    for path in ('Sources/Kamus/Resources/KamusMark.png',):
        save(template, path)

    catalog = RESOURCES / 'Brand.xcassets'
    catalog.mkdir(exist_ok=True)
    (catalog / 'Contents.json').write_text(json.dumps({'info': {'author': 'xcode', 'version': 1}}, indent=2) + '\n')
    for name, image in (('KamusLogo', logo), ('KamusMark', template)):
        directory = catalog / (name + '.imageset')
        directory.mkdir(exist_ok=True)
        image.save(directory / (name + '.png'))
        contents = {'images': [{'filename': name + '.png', 'idiom': 'universal'}], 'info': {'author': 'xcode', 'version': 1}}
        if name == 'KamusMark':
            contents['properties'] = {'template-rendering-intent': 'template'}
        (directory / 'Contents.json').write_text(json.dumps(contents, indent=2) + '\n')

    # macOS icon plate retains the platform's outer transparent margin.
    plate_size = 824
    plate = full.resize((plate_size, plate_size), Image.Resampling.LANCZOS).convert('RGBA')
    clip = Image.new('L', (plate_size * 4, plate_size * 4))
    ImageDraw.Draw(clip).rounded_rectangle((0, 0, clip.width - 1, clip.height - 1), radius=plate_size * 0.22 * 4, fill=255)
    plate.putalpha(clip.resize(plate.size, Image.Resampling.LANCZOS))
    mac = Image.new('RGBA', (1024, 1024))
    mac.alpha_composite(plate, (100, 100))
    save(mac, 'Resources/AppIcon-preview.png')
    save(mac, 'promo/public/icon.png')
    iconset = RESOURCES / 'AppIcon.iconset'
    iconset.mkdir(exist_ok=True)
    for size in (16, 32, 128, 256, 512):
        for scale in (1, 2):
            suffix = '' if scale == 1 else '@2x'
            mac.resize((size * scale, size * scale), Image.Resampling.LANCZOS).save(iconset / f'icon_{size}x{size}{suffix}.png')
    subprocess.run(['iconutil', '-c', 'icns', str(iconset), '-o', str(RESOURCES / 'AppIcon.icns')], check=True)
    shutil.rmtree(iconset)

    # Adaptive launcher: transparent foreground with the mark inside safe bounds.
    # Use the source mark's colors at the same geometry, avoiding recoloring.
    crop = master.crop(ImageChops.subtract(master.getchannel('R'), master.getchannel('B')).point(lambda v: min(255, v * 8)).getbbox()).convert('RGBA')
    crop.putalpha(mask)
    crop.thumbnail((216, 216), Image.Resampling.LANCZOS)
    foreground = Image.new('RGBA', (432, 432))
    foreground.alpha_composite(crop, ((432 - crop.width) // 2, (432 - crop.height) // 2))
    save(foreground, 'android/app/src/main/res/drawable-nodpi/kamus_launcher_foreground.png')
    print('Updated macOS, iOS, Android, action extension, widget and promo assets from kamus.png.')


if __name__ == '__main__':
    main()
