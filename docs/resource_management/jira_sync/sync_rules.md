# JIRA Sync Rules

JIRA 연계를 자동화하려면 "JIRA를 그대로 보여주는 것"보다, JIRA 데이터를 Markdown 운영 체계에 맞게 변환하는 것이 중요하다.

## 연계 대상

### 프로젝트

- `Epic Key`
- `Epic Name`
- `Assignee`
- `Start Date`
- `Due Date` 또는 `Target End`
- `Status`
- `Team` 또는 `Component`

### 운영/개선

- `Task Key`
- `Summary`
- `Assignee`
- `Start Date`
- `Due Date`
- `Status`
- `Label` 또는 `Component`

## 추천 규칙

### 1. 프로젝트는 EPIC 단위로 월간 파일에 반영

- EPIC 하나에 담당자가 여러 명이면, 핵심 담당만 분기 파일에 노출
- 세부 담당자는 월간 파일에 기록

### 2. 운영/개선은 개별 TASK를 바로 상단에 노출하지 않는다

- `label=ops-board` 또는 특정 컴포넌트 기준으로 집계
- 같은 테마의 TASK는 운영 묶음으로 표현

예시:

- `전시 운영 자동화`
- `주문/결제 안정화`
- `사내몰 권한 개선`

### 3. 자동 반영 빈도

- 하루 1회 배치 또는 평일 2회
- 오전 9시, 오후 5시 권장

### 4. 사람이 최종 승인

- JIRA 변경값을 그대로 본문 파일에 덮어쓰지 않는다
- 자동화 에이전트가 초안 파일 또는 변경 제안 생성
- 팀장 또는 운영 담당이 확인 후 확정

## 자동화 구조 예시

1. JIRA API 조회
2. EPIC/TASK를 표준 포맷으로 변환
3. 월간 Markdown 테이블 갱신
4. Mermaid Gantt 구간 재생성
5. 변경 로그 기록

## 권장 예외 처리

- 시작일이 없는 티켓은 미배정 후보로 별도 분리
- 종료일이 없는 티켓은 기본 종료예정일 규칙 적용 또는 검토 필요 표시
- 담당자가 없는 티켓은 `unassigned`로 분리
- 한 사람이 같은 기간 100% 초과 시 충돌 경고 출력

## 구현 방법

가벼운 구현은 아래 중 하나가 현실적이다.

- JIRA API + 스크립트로 Markdown 파일 생성
- JIRA Automation + Webhook + 로컬 스크립트
- Google Sheet 중간 집계 후 Markdown 변환

23명 규모에서는 첫 번째 방식이 가장 단순하다.
