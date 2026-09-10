#!/usr/bin/env python3
"""Extract individual stickers from the pack-*.png sheets.

pack-4-1.png already has a transparent background -> split by alpha blobs.

pack-8-*.png sit on a dark vignette with irregular, slightly overlapping
layout that automatic segmentation handles badly. Instead we crop
hand-tuned rectangles and fade each to a soft oval vignette (opaque
centre, transparent edges) plus a mild dark-pixel knockout. On the ivory
card each sticker then reads as a framed portrait; box slop is hidden by
the falloff.

Outputs RGBA PNGs to assets/stickers/extracted/ and a debug montage to
build/sticker_debug/.
"""
from __future__ import annotations

import json
import pathlib
import sys

import cv2
import numpy as np

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "assets" / "stickers"
OUT = SRC / "extracted"
DEBUG = ROOT / "build" / "sticker_debug"

# Hand-tuned boxes (x0, y0, x1, y1) in source pixels for the 1536x1024 sheets.
BOXES: dict[str, list[tuple[int, int, int, int]]] = {
    "p81": [
        (10, 60, 470, 560), (430, 110, 835, 505), (825, 10, 1075, 510),
        (1150, 80, 1525, 480), (70, 515, 440, 1015), (430, 500, 800, 1010),
        (835, 495, 1110, 1015), (1090, 545, 1525, 1010),
    ],
    "p82": [
        (5, 95, 420, 485), (415, 30, 755, 500), (785, 80, 1105, 505),
        (1085, 100, 1530, 500), (0, 505, 380, 1015), (365, 545, 845, 1010),
        (785, 505, 1150, 1015), (1140, 505, 1500, 1010),
    ],
    "p83": [
        (0, 95, 445, 485), (420, 25, 775, 480), (785, 95, 1150, 470),
        (1230, 30, 1536, 480), (0, 505, 455, 965), (435, 495, 835, 955),
        (835, 485, 1150, 965), (1115, 505, 1536, 995),
    ],
}


def _trim_alpha(rgba: np.ndarray, pad: int = 4) -> np.ndarray:
    a = rgba[:, :, 3]
    ys, xs = np.where(a > 6)
    if len(xs) == 0:
        return rgba
    x0, x1 = max(int(xs.min()) - pad, 0), min(int(xs.max()) + pad + 1, rgba.shape[1])
    y0, y1 = max(int(ys.min()) - pad, 0), min(int(ys.max()) + pad + 1, rgba.shape[0])
    return rgba[y0:y1, x0:x1]


def _oval_alpha(h: int, w: int, inner: float = 0.70, outer: float = 1.03) -> np.ndarray:
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    ny = (yy - h / 2) / (h / 2)
    nx = (xx - w / 2) / (w / 2)
    r = np.sqrt(nx * nx + ny * ny)
    a = np.clip((outer - r) / (outer - inner), 0.0, 1.0)
    return (a * a * (3 - 2 * a) * 255).astype(np.uint8)  # smoothstep


def split_transparent(path: pathlib.Path, prefix: str) -> list[str]:
    img = cv2.imread(str(path), cv2.IMREAD_UNCHANGED)
    if img.shape[2] == 3:
        raise SystemExit(f"{path.name}: expected alpha channel")
    mask = (img[:, :, 3] > 16).astype(np.uint8) * 255
    mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, np.ones((15, 15), np.uint8))
    n, _, stats, _ = cv2.connectedComponentsWithStats(mask, 8)
    boxes = sorted(
        (tuple(stats[i][:4]) for i in range(1, n) if stats[i][4] > 0.01 * mask.size),
        key=lambda b: (round(b[1] / 120), b[0]),
    )
    names = []
    for idx, (x, y, w, h) in enumerate(boxes, 1):
        p = 8
        crop = img[max(y - p, 0):y + h + p, max(x - p, 0):x + w + p].copy()
        crop = _trim_alpha(crop)
        name = f"{prefix}-{idx:02d}.png"
        cv2.imwrite(str(OUT / name), crop)
        names.append(name)
    return names


def crop_dark_pack(path: pathlib.Path, prefix: str) -> list[str]:
    bgr = cv2.imread(str(path), cv2.IMREAD_COLOR)
    h, w = bgr.shape[:2]
    names = []
    for idx, (x0, y0, x1, y1) in enumerate(BOXES[prefix], 1):
        x0, y0 = max(x0, 0), max(y0, 0)
        x1, y1 = min(x1, w), min(y1, h)
        sub = bgr[y0:y1, x0:x1].astype(np.float32)
        bh, bw = sub.shape[:2]

        oval = _oval_alpha(bh, bw, inner=0.48, outer=0.98).astype(np.float32)
        oval /= 255.0
        # Knock the dark vignette out properly: pure black -> transparent,
        # mid tones ramp up fast. Dark clothing goes a little translucent
        # (reads as a faded print) instead of leaving a grey ring.
        v = cv2.cvtColor(sub.astype(np.uint8), cv2.COLOR_BGR2HSV)[:, :, 2] / 255.0
        s = cv2.cvtColor(sub.astype(np.uint8), cv2.COLOR_BGR2HSV)[:, :, 1] / 255.0
        fg = np.clip((v - 0.16) / 0.30, 0.0, 1.0)
        fg = np.maximum(fg, np.clip((s - 0.20) / 0.30, 0.0, 1.0))
        alpha = np.clip(oval * (0.15 + 0.85 * fg), 0, 1)
        alpha = cv2.GaussianBlur(alpha, (0, 0), 2.5)

        rgba = np.dstack([sub, alpha * 255]).astype(np.uint8)
        rgba = _trim_alpha(rgba)
        name = f"{prefix}-{idx:02d}.png"
        cv2.imwrite(str(OUT / name), rgba)
        names.append(name)

    DEBUG.mkdir(parents=True, exist_ok=True)
    tiles = []
    for nm in names:
        im = cv2.imread(str(OUT / nm), cv2.IMREAD_UNCHANGED)
        canvas = np.full((340, 340, 3), (245, 240, 232), np.uint8)
        ih, iw = im.shape[:2]
        sc = min(320 / iw, 320 / ih)
        rs = cv2.resize(im, (max(int(iw * sc), 1), max(int(ih * sc), 1)))
        a = rs[:, :, 3:4].astype(np.float32) / 255.0
        oy, ox = (340 - rs.shape[0]) // 2, (340 - rs.shape[1]) // 2
        canvas[oy:oy + rs.shape[0], ox:ox + rs.shape[1]] = (
            rs[:, :, :3] * a
            + canvas[oy:oy + rs.shape[0], ox:ox + rs.shape[1]] * (1 - a)
        ).astype(np.uint8)
        tiles.append(canvas)
    cv2.imwrite(str(DEBUG / f"{prefix}.png"), np.hstack(tiles))
    return names


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for old in OUT.glob("*.png"):
        old.unlink()
    result: dict[str, list[str]] = {"p4": split_transparent(SRC / "pack-4-1.png", "p4")}
    for i in (1, 2, 3):
        result[f"p8{i}"] = crop_dark_pack(SRC / f"pack-8-{i}.png", f"p8{i}")
    total = sum(len(v) for v in result.values())
    for k, v in result.items():
        print(f"{k}: {len(v)}")
    print(f"TOTAL extracted: {total}")
    (OUT / "_manifest.json").write_text(json.dumps(result, indent=2))
    if total < 28:
        print(f"WARNING: only {total} extracted", file=sys.stderr)


if __name__ == "__main__":
    main()
