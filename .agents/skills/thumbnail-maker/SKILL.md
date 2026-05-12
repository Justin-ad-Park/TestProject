---
name: thumbnail-maker
description: 첨부 이미지를 바탕으로 로고가 포함된 쇼핑몰용 정사각형 썸네일을 생성해야 할 때 사용하는 스킬.
---

# Thumbnail Maker

## Purpose

Create a square shopping thumbnail from an attached source image for marketplace or mall usage.

## Source Of Truth

Read configuration values from:

- `.agents/skills/thumbnail-maker/config/thumbnail.toml`

Use this file as the source of truth for:

- output width
- output height
- logo asset path
- logo left offset
- logo top offset
- logo width
- default output format
- output root directory
- output subdirectory pattern
- filename rule
- timestamp filename pattern
- source-name filename pattern
- label left offset
- label bottom offset
- label gap
- label height mode
- label horizontal padding
- label font size ratio
- supported label keywords

## Workflow

1. Confirm that the user attached at least one source image.
2. Load `.agents/skills/thumbnail-maker/config/thumbnail.toml`.
3. Confirm that the logo asset exists at the configured path.
4. Detect whether the user requested `free_shipping`, `mix_and_match_discount`, custom label text, both, or no labels.
5. Resolve built-in label keywords into display text and preserve any custom label text as provided.
6. Follow the fixed thumbnail process described in `## Locked Execution Process`.
7. Determine the save directory from `output_root_dir` and `output_subdir_pattern`.
8. Determine the output filename from `filename_rule`.
9. Create the output directory if it does not already exist.
10. Save the final thumbnail into the computed directory.
11. Return the saved file path and the final thumbnail output in the configured default format unless the user explicitly requests another format.

## Locked Execution Process

This skill must preserve the current thumbnail-making process unless the project owner explicitly changes the skill.

### Required implementation path

- Use `scripts/create_thumbnail.swift` as the standard thumbnail generation script.
- Use the configured logo asset as the source of truth.
- If the logo asset is SVG and a rasterized working copy is needed for composition, generate a PNG working copy first and then compose with that PNG.
- Draw labels directly onto the final thumbnail canvas at composition time.
- Do not depend on pre-rendered label PNG assets for final label rendering.

### Required image processing behavior

1. Load the source image.
2. Convert the source into a square by using **center crop**.
3. Resize the cropped square to the configured output size.
4. Place the logo in the top-left area using:
   - configured `logo_left`
   - configured `logo_top`
   - configured `logo_width`
5. Preserve the logo aspect ratio when calculating logo height.
6. If no label is requested, do not add any bottom label overlay.
7. If exactly one label is requested, draw that label box at:
   - left: configured `label_left`
   - bottom edge: configured `label_bottom` above the bottom edge of the final thumbnail
   - height: same as the rendered logo height when `label_height_mode = match_logo_height`
8. If both labels are requested:
   - draw the first label at configured `label_left` and with its visible bottom edge `configured label_bottom` above the bottom edge
   - draw the second label on the same bottom baseline
   - start the second label at `first_label.right + configured label_gap`
9. Compute each label box width from its text width plus configured horizontal padding.
10. Compute each label box height from `label_height_mode`.
11. Compute label placement from the final visible label box, not from a pre-rendered raster asset.
12. Preserve transparency outside the label box during composition. Do not replace transparent outer pixels with white.
12. Export the result as PNG by default.

### Do not change these behaviors by default

- Do not switch from center-crop to padding, background expansion, or AI outpainting unless explicitly requested.
- Do not change the logo position from top-left unless explicitly requested.
- Do not change the logo width rule from fixed-width scaling unless explicitly requested.
- Do not add labels unless the user explicitly requests them.
- Do not center a single label by default.
- Do not reorder the two-label layout by default.
- When both labels are requested, `free_shipping` must stay left of `mix_and_match_discount`.
- Treat `free_shipping` as display text `무료배송`.
- Treat `mix_and_match_discount` as display text `골라담아할인`.
- If the user provides custom label text, render that text directly inside the label box.
- Do not replace the Swift composition script with another implementation path unless the project intentionally updates the standard process.
- Do not change the save path convention unless the configuration is intentionally updated.

## Rules

- Do not distort the logo.
- Do not change configured spacing values unless the user requests a configuration change.
- Prefer a clean composition that preserves the source subject clearly.
- If square conversion requires cropping, avoid cutting the main product unless the user explicitly allows it.
- If the input image is not square and no other rule is provided, prefer conservative center-crop behavior that preserves the main subject.
- The default square conversion rule is center crop.
- Compute label positions against the final thumbnail canvas.
- Use `label_height_mode` as the source of truth for visible label size.
- When `label_height_mode = match_logo_height`, use the rendered visible logo height as the label height.
- Treat `label_left` as the visible label box left edge.
- Treat `label_bottom` as the visible label box bottom offset from the thumbnail bottom edge.
- Compute label width from rendered text width plus `label_horizontal_padding`.
- Compute label font size from the label height and `label_font_size_ratio`.
- When `filename_rule = "timestamp"`, use `filename_timestamp_pattern`.
- When `filename_rule = "source_name"`, derive the filename from the source image name, sanitize unsafe characters, and apply `filename_source_pattern`.

## Missing Information Handling

- If no source image is attached, ask for the image.
- If the logo asset is unavailable, report the missing asset path clearly.
- If the user requests a built-in label keyword that is unsupported, report the unsupported keyword clearly.
- If the requested output conflicts with the configuration, state the conflict and ask whether to update the configuration or override only for the current run.
- If the source image has no usable filename and `filename_rule = "source_name"`, fall back to the timestamp filename rule.

## Related Files

- `.codex/agents/thumbnail_maker.toml`
- `.agents/skills/thumbnail-maker/config/thumbnail.toml`
- `.agents/skills/thumbnail-maker/references/thumbnail-spec.md`
- `scripts/create_thumbnail.swift`
- `docs/design_harness_guide/02.썸네일_에이전트_만들기.md`
