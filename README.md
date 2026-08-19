# SILLAGE — Maison de Parfum

A scroll-driven cinematic landing page for **Sillage Nº 1**, a luxury extrait de
parfum. As the visitor scrolls, a pre-rendered camera glides in one continuous,
uncut shot through the perfume's world — dawn lavender fields in Grasse, the
copper-still atelier, the marble boutique, and finally a slow half-orbit around
the Nº 1 bottle. Scroll position scrubs time along a single camera path; there
are no cuts or transitions, only frame-locked seams between clips.

Built with the [lets-scroll](../lets-scroll-main) agent skill (manual asset
path: stills and clips rendered in external AI tools from this repo's prompt
files, then validated, frame-chained and encoded locally).

## Run it

Fully static — no build step, no dependencies:

```bash
cd sillage
python3 -m http.server 8123
# open http://localhost:8123
```

Any static host works as-is (Netlify, Vercel, GitHub Pages, S3…). The page
loads each clip as an in-memory Blob, so it does **not** depend on the server
supporting HTTP byte ranges.

## The journey

| # | Scene | Beat | Copy |
|---|---|---|---|
| 1 | The Harvest | Dawn glide over the lavender rows toward the farmhouse | "Grown, not manufactured." |
| 2 | The Atelier | Low track alongside the copper alembic stills | "Distilled drop by drop." |
| 3 | The Boutique | Through the brass doorway to the marble discovery bar | "Find your signature." |
| 4 | Nº 1 | Half-orbit around the bottle on its plinth + CTA | "One drop says everything." |

Camera architecture: **continuous walkthrough** (one unbroken forward glide, no
connector clips). Each leg starts from the previous leg's actual rendered last
frame, which is what makes the seams invisible.

## Repository layout

```
sillage/
├── index.html            page + engine config (sections, copy, palette, pacing)
├── scrub-engine.js       scroll-scrub engine (vanilla JS, self-contained)
├── assets/               site assets
│   ├── *.webp            scene posters (also lazy-load fallbacks)
│   └── vid/*.mp4         the 4 camera legs (720p, GOP 8, faststart, no audio)
├── work/                 asset pipeline workspace
│   ├── still_*.txt       scene-still prompts (identical style preamble)
│   ├── dive_*.txt        leg prompts (motion-handoff contract)
│   ├── still_*.png       rendered stills (input)
│   ├── dive_*.mp4        rendered legs (input)
│   └── first_/last_*.png extracted seam frames
├── scripts/              validation + encode pipeline (bash 3.2 safe)
└── HANDOFF.md            the render spec: prompt ↔ conditioning frame ↔ status
```

## Re-rendering / replacing assets

The asset chain is sequential — see `HANDOFF.md` for the full spec. In short:

1. Render stills from `work/still_*.txt` (16:9, ≥1920 px), drop into `work/`.
2. Render legs **in order** from `work/dive_*.txt`, each conditioned on the
   previous leg's extracted last frame (`work/last_<scene>.png`), ~8 s, 16:9,
   no audio, drop into `work/`.

Then re-run the pipeline:

```bash
bash scripts/validate_stills.sh   # present, 16:9, ≥1200 px wide
bash scripts/extract_frames.sh    # first_/last_ PNGs per leg
bash scripts/validate_legs.sh     # geometry, duration, frame-0 vs start frame (PSNR)
bash scripts/encode.sh            # assets/vid/*.mp4 + assets/*.webp
```

`validate_legs.sh` PSNR bands (frame 0 vs the handed-over start frame):
**≥ 25 dB** pixel-locked, **15–25 dB** conditioning re-rendered — accept only if
the composition matches (the engine's seam crossfade covers it), **< 15 dB**
different composition — re-render.

## Theming

Palette and fonts live in `index.html` as CSS custom properties
(`--sw-bg`, `--sw-ink`, `--sw-accent`, `--sw-font-display`, …); each section
overrides the accent at runtime. Copy, pacing (`scroll`, `linger`) and CTAs are
in the `mountLetsScroll` config in the same file.

## Notes / caveats

- The rendered clips carry the source video tool's sparkle watermark
  (bottom-right). Re-render watermark-free and re-run `scripts/encode.sh` to
  replace them — nothing else changes.
- Desktop-optimized; phones get the same clips with posters and the engine's
  mobile hardening (seek coalescing, iOS priming, safe areas), but no native
  9:16 portrait chain.
- `prefers-reduced-motion` falls back to the still posters, no video.

## License

Site content and assets: all rights reserved. `scrub-engine.js` and the
`lets-scroll` skill: MIT (see [../lets-scroll-main/LICENSE](../lets-scroll-main/LICENSE)).
