# Kâmus tanıtım videosu

[Remotion](https://www.remotion.dev) ile kodlanmış 34 saniyelik tanıtım videosu (1920×1080, 30 fps, sessiz).

```bash
npm install
npm run studio   # tarayıcıda önizleme ve kare kare düzenleme
npm run render   # out/kamus-promo.mp4
```

Sahneler `src/scenes/` altında, sıraları ve süreleri `src/Promo.tsx` içindeki `SCENES` dizisinde.
Renkler ve yazı tipleri `src/theme.ts` içinde; palet `scripts/make_icon.py` ile aynıdır.
Yazı tipleri sistemden gelir (Georgia, SF Pro), bu yüzden render macOS'ta alınmalıdır.
Popover'daki "müstesna" maddesi sozluk.gov.tr'nin gerçek yanıtından alınmıştır.
