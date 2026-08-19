# SILLAGE — asset handoff spec

Manual render path. You render every asset from the prompt files below (any image
tool for stills; a **start-frame-capable** video tool for the clips — Kling, Runway,
Seedance, Hailuo, Pika…). Drop the finished files into **`work/`** (this folder) and
tell me; I validate, extract the seam frames, encode, and wire the page.

Chain order: `harvest → atelier → boutique → finale` (one continuous forward glide —
Architecture A, **no connector clips**).

## Phase 1 — scene stills

Spec per still: **16:9 landscape, ≥ 1920 px wide, no text/logos**, exactly the style
the prompt file describes (identical preamble on all four — that's what makes the
world cohesive). Save as PNG (or high-quality JPG).

| Prompt file | Save as | Status |
|---|---|---|
| `work/still_harvest.txt` | `work/still_harvest.png` | accepted (1672×941) |
| `work/still_atelier.txt` | `work/still_atelier.png` | accepted (1672×941) |
| `work/still_boutique.txt` | `work/still_boutique.png` | accepted (1672×941) |
| `work/still_finale.txt` | `work/still_finale.png` | accepted (1672×941) |

## Phase 2 — video legs (SEQUENTIAL — one at a time, in order)

Each leg **must start on the exact conditioning frame below** — that's what makes the
seams invisible. Leg N's conditioning frame is extracted from leg N−1's rendered
video, so render **one leg, hand it back, I extract its last frame, then you render
the next**. I'll keep the "Start frame" column filled with the real files as we go.

Spec per leg: **16:9 landscape, ~8 s, highest quality your tool offers, no audio**.
The start frame must be obeyed exactly (the tool's first-frame/image-to-video mode).
No end frame needed — the prompt steers where the camera goes.

| # | Prompt file | Start frame (conditioning) | Save as | Status |
|---|---|---|---|---|
| 1 | `work/dive_harvest.txt` | `work/still_harvest.png` | `work/dive_harvest.mp4` | accepted (720p, 10s, PSNR 28.2 dB) |
| 2 | `work/dive_atelier.txt` | `work/last_harvest.png` | `work/dive_atelier.mp4` | accepted (720p, 10s, composition-locked) |
| 3 | `work/dive_boutique.txt` | `work/last_atelier.png` | `work/dive_boutique.mp4` | accepted (720p, 10s, PSNR 34.4 dB) |
| 4 | `work/dive_finale.txt` | `work/last_boutique.png` | `work/dive_finale.mp4` | accepted (720p, 10s, PSNR 34.1 dB) |

## Acceptance rules (what I check on each drop)

- **Stills**: all 4 present, each opens, aspect ≈ 16:9, width ≥ ~1200 px, reads as
  one cohesive world (same light, palette, mood). Off-style stills go back for a
  re-roll (re-run the same prompt, optionally with an approved sibling as style
  reference).
- **Legs**: plays, 16:9, duration ≈ 8 s (5–12 s fine), and **frame 0 matches the
  handed-over start frame** (I diff them — a tool that ignored the start image can't
  hold its seam, so that clip goes back for re-generation; no crossfade fixes a
  wrong start).
- **Last frame reads as a calm forward glide** (no sideways blur, no half-finished
  orbit) — a bad handoff frame poisons every leg after it, so I check before we
  render the next one. Budget ~1 re-roll per leg.

## After the last leg lands

I encode everything for scrubbing (`scripts/encode.sh`: native res, crf 20, GOP 8,
faststart, no audio) into `assets/`, and the page is done. Preview locally with:

```bash
cd sillage && python3 -m http.server 8000
# open http://localhost:8000
```
