#!/usr/bin/env python3
"""Extract individual stickers from the pack-*.png sheets.

pack-4-1.png already has a transparent background -> split by alpha blobs.

pack-8-*.png sit on a dark vignette with an irregular, slightly overlapping
layout, so automatic subject detection is unreliable -- instead we crop
hand-tuned rectangles (BOXES below, one per sticker) and then run GrabCut
inside each crop to cut the actual silhouette out, seeded with a
conservative "definitely background" border and a "probably foreground"
core matching the hand-tuned box. This replaces the earlier oval-vignette
fade (which left visible dark/blurred halos around several stickers) with
a real cutout, matching the clean look of the transparent-source stickers.

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
# These are the "core" region -- GrabCut is seeded assuming the subject
# mostly fills this box, with a padded margin around it treated as
# background.
# Stickers where GrabCut reliably fuses the subject with an adjacent dark
# background patch of similar tone (no seeding/morphology tweak separated
# them cleanly) -- these go straight to the oval-vignette fallback instead.
FORCE_OVAL: set[tuple[str, int]] = {
    ("p81", 4), ("p81", 5), ("p82", 7), ("p83", 7),
}

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


def _oval_alpha(h: int, w: int, inner: float = 0.48, outer: float = 0.98) -> np.ndarray:
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    ny, nx = (yy - h / 2) / (h / 2), (xx - w / 2) / (w / 2)
    r = np.sqrt(nx * nx + ny * ny)
    a = np.clip((outer - r) / (outer - inner), 0.0, 1.0)
    return a * a * (3 - 2 * a)  # smoothstep, 0..1


def _oval_fallback(bgr: np.ndarray) -> np.ndarray:
    """Safe fallback when GrabCut leaks background: oval vignette + a
    brightness/saturation floor so the dark surrounding fades out instead
    of leaving a hard blob."""
    h, w = bgr.shape[:2]
    oval = _oval_alpha(h, w)
    hsv = cv2.cvtColor(bgr, cv2.COLOR_BGR2HSV).astype(np.float32) / 255.0
    fg = np.clip((hsv[:, :, 2] - 0.16) / 0.30, 0.0, 1.0)
    fg = np.maximum(fg, np.clip((hsv[:, :, 1] - 0.20) / 0.30, 0.0, 1.0))
    alpha = np.clip(oval * (0.15 + 0.85 * fg), 0, 1) * 255
    return cv2.GaussianBlur(alpha.astype(np.uint8), (0, 0), 2.5)


def _grabcut_cutout(bgr: np.ndarray, core_frac: float = 0.86) -> np.ndarray | None:
    """Returns an alpha mask (uint8, 0..255) cutting the subject out of
    [bgr], seeded with a background border and a foreground core sized
    [core_frac] of the crop, or None if the result looks like it leaked
    background (implausibly large / touches most of the border).
    """
    h, w = bgr.shape[:2]
    gc_mask = np.full((h, w), cv2.GC_PR_BGD, np.uint8)

    cx0, cy0 = int(w * (1 - core_frac) / 2), int(h * (1 - core_frac) / 2)
    cx1, cy1 = w - cx0, h - cy0
    gc_mask[cy0:cy1, cx0:cx1] = cv2.GC_PR_FGD

    border = max(3, int(min(h, w) * 0.08))
    gc_mask[:border, :] = cv2.GC_BGD
    gc_mask[-border:, :] = cv2.GC_BGD
    gc_mask[:, :border] = cv2.GC_BGD
    gc_mask[:, -border:] = cv2.GC_BGD

    bgd, fgd = np.zeros((1, 65), np.float64), np.zeros((1, 65), np.float64)
    try:
        cv2.grabCut(bgr, gc_mask, None, bgd, fgd, 6, cv2.GC_INIT_WITH_MASK)
    except cv2.error:
        return None

    alpha = np.where(
        (gc_mask == cv2.GC_FGD) | (gc_mask == cv2.GC_PR_FGD), 255, 0
    ).astype(np.uint8)
    alpha = cv2.morphologyEx(alpha, cv2.MORPH_CLOSE, np.ones((9, 9), np.uint8))

    # A leaked background patch is usually joined to the real subject by a
    # thin isthmus. A small open() (5x5, as before) doesn't break that; a
    # much bigger one does. Find the main blob using a heavy open, then
    # restore its true (unblocky) edges by masking the original alpha with
    # a generous dilation of that surviving core -- this keeps the subject's
    # real silhouette while dropping anything only weakly attached to it.
    core = cv2.morphologyEx(alpha, cv2.MORPH_OPEN, np.ones((23, 23), np.uint8))
    n, labels, stats, _ = cv2.connectedComponentsWithStats(core, 8)
    if n <= 1:
        return None
    keep = 1 + int(np.argmax(stats[1:, 4]))
    seed = np.where(labels == keep, 255, 0).astype(np.uint8)
    seed = cv2.dilate(seed, np.ones((29, 29), np.uint8))
    alpha = cv2.bitwise_and(alpha, seed)
    alpha = cv2.morphologyEx(alpha, cv2.MORPH_OPEN, np.ones((5, 5), np.uint8))

    # Reject implausible cutouts: a real subject inside this padded crop
    # shouldn't fill most of it, and shouldn't hug the border on every side
    # (both are signs GrabCut fused the subject with leaked background).
    coverage = float((alpha > 0).mean())
    border_hit = sum(
        [
            alpha[0, :].mean() > 40,
            alpha[-1, :].mean() > 40,
            alpha[:, 0].mean() > 40,
            alpha[:, -1].mean() > 40,
        ]
    )
    if coverage < 0.03 or coverage > 0.62 or border_hit >= 3:
        return None

    return cv2.GaussianBlur(alpha, (0, 0), 1.2)


def crop_dark_pack(path: pathlib.Path, prefix: str) -> list[str]:
    bgr_full = cv2.imread(str(path), cv2.IMREAD_COLOR)
    h, w = bgr_full.shape[:2]
    names = []
    for idx, (bx0, by0, bx1, by1) in enumerate(BOXES[prefix], 1):
        # Pad the hand-tuned box so GrabCut has real background context on
        # every side to learn from.
        bw, bh = bx1 - bx0, by1 - by0
        pad_x, pad_y = int(bw * 0.22), int(bh * 0.22)
        x0, y0 = max(bx0 - pad_x, 0), max(by0 - pad_y, 0)
        x1, y1 = min(bx1 + pad_x, w), min(by1 + pad_y, h)
        sub = bgr_full[y0:y1, x0:x1]

        if (prefix, idx) in FORCE_OVAL:
            alpha = _oval_fallback(sub)
        else:
            # The core (probably-foreground) region should match the
            # original hand-tuned box, as a fraction of the padded crop.
            core_frac = min((bx1 - bx0) / (x1 - x0), (by1 - by0) / (y1 - y0))
            alpha = _grabcut_cutout(sub, core_frac=min(core_frac, 0.9))
            if alpha is None:
                alpha = _oval_fallback(sub)
                print(f"  {prefix}-{idx:02d}: GrabCut leaked, used oval fallback")

        rgba = np.dstack([sub, alpha])
        rgba = _trim_alpha(rgba, pad=3)
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
