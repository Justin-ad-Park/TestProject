# AGENTS.md

## 프로젝트 개요

이 프로젝트는 쇼핑몰 디자인팀의 이미지 생성 하네스 프로젝트다.

목표는 디자인 업무 유형별로 전용 서브에이전트와 스킬을 만들고,  
요청 방식, 제약사항, 검수 기준, 개선 로그를 지속적으로 축적하는 것이다.

---

## 현재 우선 대상

현재 가장 먼저 만드는 대상은 **썸네일 생성 서브에이전트**다.

- subagent: `thumbnail_maker`
- skill: `thumbnail-maker`

---

## Subagent 사용 규칙

- 썸네일 이미지 생성 요청은 `thumbnail_maker` 서브에이전트를 우선 사용한다.
- `thumbnail_maker`는 연결된 `thumbnail-maker` 스킬의 작업 절차와 구성값을 따른다.
- 썸네일 스킬의 실행 기준 문서는 `.agents/skills/thumbnail-maker/SKILL.md` 하나로 고정한다.
- `.agents/skills/thumbnail-maker/SKILL.ko.md`는 사람용 한글 설명 문서이며, 에이전트는 실행 기준으로 참조하지 않는다.
- 썸네일 기본 규격과 로고 값은 `.agents/skills/thumbnail-maker/config/thumbnail.toml`을 기준으로 본다.
- 썸네일 결과물 저장 경로와 파일명 규칙도 `.agents/skills/thumbnail-maker/config/thumbnail.toml`을 기준으로 본다.
- 당직표 작성 또는 당직 보고서 정리 작업은 `.agents/skills/dangjik-html-formatter/SKILL.md`를 우선 참조한다.
- 추후 배너, 상품상세, 이벤트, 기획전, 외부몰용 서브에이전트를 같은 방식으로 추가한다.

---

## 당직표 작업 규칙

- 당직표 작성, 당직 보고 메일 정리, 사업장별 근무현황 반영 요청은 `dangjik-html-formatter` 스킬을 우선 사용한다.
- 당직표 작업의 실행 기준 문서는 `.agents/skills/dangjik-html-formatter/SKILL.md` 하나로 본다.
- 기존 HTML 표 구조, 메일 문구, 행 순서, `pending` 처리 방식은 스킬 정의를 기준으로 유지한다.
- 오전/오후 재보고가 함께 있을 때는 스킬의 업데이트 규칙을 따른다.
- 당직표 기본 출력 경로는 `outputs/dangjik/YYYYMMDD/YYYYMMDD_당직표.html` 로 본다.

---

## 파일 연결 구조

```text
/AGENTS.md
/.codex/agents/thumbnail_maker.toml
/.agents/skills/thumbnail-maker/SKILL.md
/.agents/skills/thumbnail-maker/SKILL.ko.md
/.agents/skills/thumbnail-maker/config/thumbnail.toml
/.agents/skills/thumbnail-maker/assets/pulmuone-shop.svg
/.agents/skills/dangjik-html-formatter/SKILL.md
/.agents/skills/dangjik-html-formatter/assets/dangjik_empty_template.html
/outputs/thumbnails/YYYYMM/DD/
/outputs/dangjik/YYYYMMDD/
/docs/design_harness_guide/01.최초가이드.md
/docs/design_harness_guide/02.썸네일_에이전트_만들기.md
```

---

## 문서 우선순위

썸네일 관련 작업을 다룰 때는 아래 순서로 문맥을 이해한다.

1. `AGENTS.md`
2. `.codex/agents/thumbnail_maker.toml`
3. `.agents/skills/thumbnail-maker/SKILL.md`
4. `.agents/skills/thumbnail-maker/config/thumbnail.toml`
5. `/docs/design_harness_guide/02.썸네일_에이전트_만들기.md`

주의:
`.agents/skills/thumbnail-maker/SKILL.ko.md`는 사람용 설명 파일이며, 에이전트의 실행 지침 우선순위에 포함하지 않는다.

당직표 관련 작업을 다룰 때는 아래 순서로 문맥을 이해한다.

1. `AGENTS.md`
2. `.agents/skills/dangjik-html-formatter/SKILL.md`
3. `.agents/skills/dangjik-html-formatter/assets/dangjik_empty_template.html`

---

## 운영 원칙

- 서브에이전트는 역할 단위로 분리한다.
- 스킬은 작업 절차와 구성값 관리에 사용한다.
- 크기, 여백, 로고 폭 같은 값은 하드코딩하지 않고 구성값으로 분리한다.
- 저장 경로와 파일명 규칙도 구성값으로 분리한다.
- 로고와 같은 브랜드 자산은 가능하면 프로젝트 내부 파일로 관리한다.
- 결과물 품질보다 먼저, 요청 방식과 제약사항이 재현 가능하게 관리되는 구조를 만든다.
