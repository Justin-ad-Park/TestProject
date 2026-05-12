---
name: dangjik-html-formatter
description: 당직 보고 메일이나 이미지에서 사업장별 당직 내용을 추출해 기존 HTML 당직표 행 형식으로 반영하고, 사업장마다 다른 표현을 정해진 문구로 통일할 때 사용하는 스킬.
---

# Duty HTML Formatter

## Purpose

Update an existing duty roster HTML file from incoming report text or report images.

Keep the current HTML output style and rewrite only the relevant site rows.

## Output Contract

- The deliverable stays as HTML.
- Preserve the current fixed-width table layout used for email sharing.
- Keep line breaks inside cells as explicit `<br>`.
- Do not redesign the page or change the overall table structure unless the user explicitly asks.
- When the roster is intended for email delivery, include the standard mail wrapper text above and below the table if the user or template expects it.
- Follow the current template wording for the mail wrapper literally, including spacing in phrases such as `보고 드립니다`.

## Source Mapping

For each incoming report, extract only the facts needed to update one row:

- site name
- duty holder
- headcount
- production status
- external visits
- special issues

When the source is an image, summarize the facts into the existing row format instead of copying the image layout.

## Row Update Rules

1. Update only the matching site row unless the user asks for broader cleanup.
2. Preserve the existing row order.
3. Replace the whole status cell content for that site with the normalized summary.
4. If the report confirms the row is updated, remove pending grey styling from that row.
5. If a site is still not updated, keep the whole row grey.

## Morning And Afternoon Update Rules

- Build the first draft from the morning report when both morning and afternoon reports exist.
- Treat the afternoon report as an update pass over the morning draft, not as a full rewrite unless the source clearly replaces the morning report.
- When the same site sends a re-report:
  - do not lower `근무인원` if the re-report shows fewer people than the existing draft
  - update `근무인원` when the re-report confirms a higher number or the first reliable number
  - append newly confirmed `생산` details to the existing morning content instead of replacing already confirmed items, unless the source explicitly says the earlier item was wrong
  - append or refresh newly confirmed `외부방문` details
  - update `특이사항` only when the re-report explicitly adds or changes an issue state
- Prefer preserving already confirmed morning facts unless the afternoon report clearly supersedes them.

## Canonical Wording

Normalize wording across all sites to these labels:

- `1. 근무인원`
- `2. 생산`
- `3. 외부방문`
- `4. 특이사항`

Additional rules:

- Convert `외부 방문자`, `업체방문`, `외부방문 및 공사 업체` to `외부방문`.
- Convert `생산라인`, `생산현황` to `생산`.
- Keep `생산(물류작업)` only when the source is explicitly about logistics work and that phrasing is already intended for the row.
- Convert `안전, 환경` to `특이사항` when it is functioning as an issue-status field rather than a separate operational section.
- Convert `ISSUE 없음` to `없음`.
- Convert `근무현황` to `근무인원`.
- Use canonical site labels already present in the HTML table even if the report uses a variant name.
- Keep `수서 본사` as a special case; it is not a production site, so its current short format can remain as-is.
- For `춘천두부/얼음` style reports, treat the roster table as the source of truth for worker count and convert the separate tofu/ice sections into the shared row format.

## Summary Style

- Compress long report prose into short numbered sections.
- Use dash-prefixed sub-lines inside a cell when multiple sub-items are needed.
- When using dash-prefixed sub-lines, always write them as `- ` with one trailing space after the hyphen.
- Recheck final HTML rows for stray `-` bullets without a following space before finishing.
- Use production sub-lines only for sites that actually need extra breakdown.
- When a line-by-line production report can be safely simplified, collapse it into a single `2. 생산 : ...` list of product names.
- Keep concrete facts and remove greetings, signatures, and repeated narration.
- Prefer `없음` or `특이사항 없음` only when the source explicitly says so.
- If a concrete issue exists, write the concrete issue instead of `없음`.
- If a site report includes a standalone safety/environment status with no concrete issue, fold it into `특이사항 : 없음` instead of keeping a separate section.
- Do not leave `특이사항 없음` inside `생산`; move it to the last `특이사항` section.
- In `생산`, keep product names and essential work items, but remove low-value status tails such as `생산중` when the item is already understandable without it.
- In simplified production summaries, omit non-producing line labels such as `라인운휴`, `휴무`, or `생산없음` unless that absence is operationally important.
- Prefer shorter normalized wording for no-run states, for example convert `전라인 가동 없음` to `가동 없음` when no meaning is lost.
- If a reported total quantity conflicts with the visible itemized quantities, keep the itemized quantities and remove the conflicting total rather than inventing a corrected number.
- `외부방문` must always contain visit details when visits exist, and must be `없음` when no visit exists.
- `특이사항` must be the last section, and when there is no issue it must be written as `{번호}. 특이사항 : 없음`.
- For `춘천두부/얼음`, summarize production separately as `- 두부공장` and `- 얼음공장`.
- For `춘천두부/얼음`, when a staffing image lists day/night workers for the target date, count each filled worker entry for that date to derive `근무인원`.
- For `춘천두부/얼음`, when the report includes next-day outside-work schedules, keep them under `외부방문` with explicit site-first date tags such as `-두부공장(5/2 토)` and `-두부공장(5/3 일)`.
- For `음성물류`, use the logistics-center format with morning/afternoon headcount and afternoon work progress instead of the normal production/visit structure when the report is about sorter/DPS/DAS progress.
- For `음성물류`, derive morning/afternoon `근무인원` from the `현장 근무인원` table's `출근` totals when that table is present.
- For `음성물류`, derive `작업진척률` from the afternoon progress table and include `계획물량` as well when it is visible in the report.

## Formatting Patterns

Use the simplest pattern that matches the site data.

### Standard single-site pattern

```html
1. 근무인원 : 17명<br>
2. 생산 : 충진, 포장 라인 가동<br>
3. 외부방문 : 없음<br>
4. 특이사항 : 없음
```

### Production sub-lines pattern

```html
1. 근무인원 : 41명<br>
2. 생산<br>
- 1~3라인 : 제품A, 제품B, 제품C<br>
- 4라인 : 생산없음, 5라인 : 휴무<br>
3. 외부방문 : 없음<br>
4. 특이사항 : 없음
```

### Simplified production list pattern

```html
1. 근무인원 : 41명<br>
2. 생산 : 제품A, 제품B, 제품C, 제품D<br>
3. 외부방문 : 없음<br>
4. 특이사항 : 없음
```

### Dual-site pattern

```html
1. 근무인원 : 의령 27명, 에프에프 1명<br>
2. 생산<br>
- 의령 : 생산 내용<br>
- 에프에프 : 생산 없음<br>
3. 외부방문<br>
- 의령 : 없음<br>
- 에프에프 : 없음
```

### Chuncheon tofu/ice pattern

```html
1. 근무인원 : 4명<br>
2. 생산<br>
- 두부공장 : 생산 없음<br>
- 얼음공장 : 생산 없음<br>
3. 외부방문<br>
- 두부공장(5/2 토) : 업체명 인원(작업내용)<br>
- 얼음공장(5/2 토) : 없음<br>
- 두부공장(5/3 일) : 업체명 인원(작업내용)<br>
- 얼음공장(5/3 일) : 없음<br>
4. 특이사항 : 없음
```

### Eumseong logistics pattern

```html
1. 근무인원 : 오전 66명, 오후 118명<br>
2. 작업진척률(오후 4시 기준)<br>
- 소터 : 15,508 Box, 진척률 65%(계획 23,751 Box)<br>
- DPS/DAS : 26,140 EA, 진척률 69%(계획 37,444 EA)
```

### Logistics-work pattern

```html
1. 근무인원 : 5명<br>
- 자사 : 1명(당직근무자)<br>
- 협력사 : 4명(경비근무자 1명, 생산도급사 3명)<br>
2. 생산(물류작업)<br>
- 생산작업 없음, 선입고 재고 보충 작업 및 출하 작업<br>
3. 외부방문 : 없음<br>
4. 특이사항 : 없음
```

## Pending Row Style

Use a shared row class for not-yet-updated sites:

```html
<tr class="pending">
```

Keep the grey style applied to the full row:

```css
.pending td {
  color: #9a9a9a;
}
```

Remove the `pending` class immediately after the row is updated from a confirmed report.

## Editing Discipline

- Make minimal edits.
- Avoid touching unrelated rows.
- Avoid renaming labels that are already canonical.
- Do not change widths, typography, or table borders unless the user asks.
- When applying an afternoon update, change only the fields that actually changed.

## Related Files

- `assets/dangjik_empty_template.html`
- `examples/260502_당직표_예시.html`

## Output Path

Edit this section first if your team wants a different save location.

- Default output path rule: save finished HTML to `./outputs/dangjik/YYYYMMDD/YYYYMMDD_당직표.html` unless the user explicitly requests another path.
