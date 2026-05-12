# 당직 에이전트 공유용 안내

## 구성 파일

- `SKILL.md`
  - GPT 앱이나 Codex 계열 도구에서 실제 작업 기준으로 쓰는 문서
- `SKILL_한글설명.md`
  - 사람이 빠르게 이해하기 위한 설명 문서
- `assets/dangjik_empty_template.html`
  - 빈 HTML 당직표 양식
- `examples/260502_당직표_예시.html`
  - 실제로 채워진 예시

## 사용 권장 방식

1. 공유받는 사람이 이 폴더 전체를 자신의 작업 폴더로 복사합니다.
2. 실제 작업 기준 문서는 `SKILL.md`만 사용합니다.
3. 새 당직표를 만들 때는 `assets/dangjik_empty_template.html`을 복사해서 날짜별 파일로 저장한 뒤 업데이트합니다.
4. 예시 표현은 `examples/260502_당직표_예시.html`을 참고합니다.

## 권장 출력 경로

하드코딩된 절대경로보다 워크스페이스 기준 상대경로를 권장합니다.

권장 형식:

```text
./outputs/dangjik/YYYYMMDD/YYYYMMDD_당직표.html
```

예:

```text
./outputs/dangjik/20260502/20260502_당직표.html
```

## Windows 사용자 권장안

Windows 사용자도 같은 구조를 쓰려면 절대경로 대신 상대경로를 쓰는 것이 가장 안전합니다.

가장 권장:

```text
./outputs/dangjik/20260502/20260502_당직표.html
```

이 방식의 장점:

- macOS, Windows 모두 동일한 규칙 사용 가능
- 드라이브 문자(`C:\`, `D:\`) 차이를 신경 쓰지 않아도 됨
- GPT 앱에서 작업 폴더만 맞추면 그대로 재사용 가능

절대경로가 꼭 필요하면 Windows에서는 아래처럼 잡는 것을 권장합니다.

```text
C:\Work\dangjik-agent\outputs\dangjik\20260502\20260502_당직표.html
```

하지만 공유용 표준은 절대경로가 아니라 상대경로로 두는 편이 좋습니다.

## 공유 시 전달 문구 권장

- “실제 작업 기준은 `SKILL.md`만 사용”
- “빈 양식은 `assets/dangjik_empty_template.html` 사용”
- “출력 파일은 `./outputs/dangjik/YYYYMMDD/` 아래 저장 권장”
