# Thumbnail Spec

## Current Default Spec

- Output size: `600 x 600`
- Logo position: top-left
- Logo left offset: `25px`
- Logo top offset: `25px`
- Logo width: `200px`
- Logo ratio: preserve original ratio
- Label left offset: `25px`
- Label bottom offset: `25px`
- Label gap: `25px`
- Label height mode: `match_logo_height`
- Label height rule: use the rendered visible logo height
- Label width rule: derive from rendered text width plus horizontal padding
- Label horizontal padding: `18px` on each side
- Label font size rule: `label height * 0.44`
- Supported built-in label keywords: `free_shipping`, `mix_and_match_discount`
- Default label border color: `#000000`
- Default label text color: `#000000`
- Per-label color input format: `labelText|borderColor|textColor`
- Default output format: `png`
- Output root directory: `outputs/thumbnails`
- Output subdirectory pattern: `YYYYMM/DD`
- Default filename rule: `timestamp`
- Timestamp filename pattern: `thumbnail_YYYYMMDD_HHMMSS.png`
- Source-name filename pattern: `{source_name}.png`
- Logo asset path: `.agents/skills/thumbnail-maker/assets/pulmuone-shop.svg`
- Source URL: `https://shop.pulmuone.co.kr/assets/pc/images/logo/pulmuone-shop.svg`

## Operational Notes

- This spec is the first working default for the thumbnail subagent.
- Default save path shape is `outputs/thumbnails/YYYYMM/DD/`.
- The locked default generation method is: `center crop -> resize to 600x600 -> top-left logo overlay -> PNG export`.
- The locked label method is:
  - no request -> no labels
  - one request -> visible left edge `25px`, visible bottom edge `25px`, height = rendered visible logo height
  - two requests -> `free_shipping` first, `mix_and_match_discount` second, gap `25px`
- Built-in keywords are rendered as:
  - `free_shipping` -> `무료배송`
  - `mix_and_match_discount` -> `골라담아할인`
- Custom label text is rendered directly at final composition time.
- If no colors are requested, label border and text are rendered in black.
- If colors are requested, they are applied per label.
- Label interior is transparent by default.
- The preferred logo path is direct SVG rasterization to a transparent PNG at the target logo width. If a fallback working logo PNG contains a near-white background, remove it before composition.
- The locked standard execution script is `scripts/create_thumbnail.swift`.
- If channel-specific thumbnail variants are added later, split them into separate config files instead of editing instructions inline.
- If crop behavior becomes important, define it explicitly here and mirror it in the skill instructions.
