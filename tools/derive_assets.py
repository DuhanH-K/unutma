"""Reproducible extraction from the visually reviewed 1536x1024 user board.

Coordinates refer to the standalone main icon, never a UI screenshot.
Original stays untouched. Pillow is explicitly permitted by the specification.
"""
from pathlib import Path
from PIL import Image, ImageDraw
import hashlib, json, sys

root = Path(__file__).resolve().parents[1]
source = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.home() / 'Downloads/ChatGPT Image 30 Ağu 2026 23_45_40.png'
board = Image.open(source).convert('RGB')
assert board.size == (1536, 1024), 'Re-inspect board before changing crop coordinates'
brand = root / 'assets/brand'
brand.mkdir(parents=True, exist_ok=True)
res = root / 'android/app/src/main/res'
# Reviewed standalone icon occupies x=486..677, y=55..247.
crop = board.crop((486, 55, 678, 247)).convert('RGBA')
mask = Image.new('L', crop.size)
ImageDraw.Draw(mask).rounded_rectangle((0, 0, 191, 191), radius=44, fill=255)
crop.putalpha(mask)
crop.resize((1024,1024), Image.Resampling.LANCZOS).save(brand/'unutma_app_icon_1024.png')
# Isolate the white bell including its gradient check-shaped cutout.
mark = Image.new('RGBA', crop.size)
for y in range(24,170):
    for x in range(35,160):
        r,g,b,a = crop.getpixel((x,y))
        alpha = max(0, min(255, (min(r,g,b)-190)*4))
        mark.putpixel((x,y),(255,255,255,alpha))
mark.resize((512,512), Image.Resampling.LANCZOS).save(brand/'unutma_logo_mark.png')
fg = Image.new('RGBA',(432,432))
fg.alpha_composite(mark.resize((288,288),Image.Resampling.LANCZOS),(72,72))
(res/'drawable-nodpi').mkdir(parents=True,exist_ok=True)
fg.save(res/'drawable-nodpi/ic_launcher_foreground.png')
for density,size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
    folder=res/f'mipmap-{density}'; folder.mkdir(parents=True,exist_ok=True)
    crop.resize((size,size),Image.Resampling.LANCZOS).save(folder/'ic_launcher.png')
    crop.resize((size,size),Image.Resampling.LANCZOS).save(folder/'ic_launcher_round.png')
for qualifier in ['mipmap-anydpi-v26','mipmap-anydpi-v33']:
    folder=res/qualifier; folder.mkdir(parents=True,exist_ok=True)
    xml='<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android"><background android:drawable="@drawable/ic_launcher_background"/><foreground android:drawable="@drawable/ic_launcher_foreground"/>'
    if qualifier.endswith('33'): xml+='<monochrome android:drawable="@drawable/ic_launcher_foreground"/>'
    xml+='</adaptive-icon>'
    for name in ['ic_launcher','ic_launcher_round']: (folder/f'{name}.xml').write_text(xml)
(res/'drawable/ic_launcher_background.xml').write_text('<shape xmlns:android="http://schemas.android.com/apk/res/android"><gradient android:startColor="#FFAA12" android:endColor="#FA1766" android:angle="270"/></shape>')
report={'source':str(source),'resolution':board.size,'sourceSha256':hashlib.sha256(source.read_bytes()).hexdigest(),'reviewed':True,'desktopAssetsFound':(Path.home()/'Desktop/UNUTMA_ASSETS').exists(),'outputs':[]}
audited_files = list(brand.glob('*.png')) + list((root/'assets/illustrations').glob('*.png'))
for file in sorted(audited_files):
    im=Image.open(file); im.verify()
    report['outputs'].append({'path':str(file.relative_to(root)), 'sha256':hashlib.sha256(file.read_bytes()).hexdigest(),'size':Image.open(file).size})
(root/'docs').mkdir(exist_ok=True)
(root/'docs/asset-audit.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report,indent=2))
