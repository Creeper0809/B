---
applyTo: '**'
---
# General Instructions
- **Language**: Always answer in **Korean (한국어)**.
- **Tone**: Be concise in conversation, but verbose and detailed in code comments and documentation.
- **Context Awareness**: Always check existing documentation and the current file structure before answering.

# Coding Standards & Workflow (CRITICAL)

## 1. Unit Testing (Mandatory)
- **Rule**: For EVERY new feature or logic change, you MUST write or update unit tests.
- **Location**: All tests must be placed in the `/test` directory.
- **Validation**: Verify that tests cover edge cases before considering the task done.

## 2. Post-Coding Workflow
After completing ANY coding task, you MUST perform the following two actions automatically without being asked:

### Action A: Update TODO List
- **File**: `/docs/(current_version)_todo.md` (Check the active version file).
- **Tasks**:
  - Mark completed tasks with `[x]`.
  - Add new tasks if the current work reveals necessary future steps.
  - Ensure the roadmap remains up-to-date.

### Action B: Write Detailed Devlog
- **File**: `/pages/devlog-YYYY-MM-DD.md` (Use today's date, e.g., `/pages/devlog-2026-01-07.md`).
- **Trigger**: 
  - After completing ANY coding task
  - **MUST write when a Phase is completed** (e.g., Phase 4.0.1, Phase 4.1.2)
- **Structure Requirement (STAR Format)**:
  1. **Situation (상황/배경)**:
     - 왜 이 작업이 필요했는가?
     - 어떤 문제를 해결하려고 했는가?
     - Phase의 목표가 무엇이었는가?
  2. **Task (과제/목표)**:
     - 구체적으로 무엇을 구현해야 했는가?
     - 어떤 기술적 요구사항이 있었는가?
     - DoD (Definition of Done)는 무엇이었는가?
  3. **Action (수행한 작업)**:
     - 어떤 코드를 변경하거나 추가했는가? (코드 스니펫 포함)
     - 어떤 파일들을 수정했는가?
     - 구현 과정에서 어떤 결정을 내렸는가?
     - **Challenges & Troubleshooting (중요)**:
       - 구체적인 어려움 (파싱 모호성, 로직 에러 등)
       - 디버깅 과정 상세 기술
       - 문제 해결 방법
  4. **Result (결과 및 최종 구현)**:
     - **각 기능마다 최종 구현 방법을 자세히 설명**:
       - 함수/클래스/모듈의 동작 원리
       - 데이터 흐름 및 제어 흐름
       - 아키텍처 결정 및 이유
     - 성능 측정 결과 (해당되는 경우)
     - 남은 과제 또는 개선 사항
     - 테스트 결과

- **Detail Level**: 
  - Phase 완료 시: 매우 상세하게 (1000+ 단어)
  - 일반 작업 완료 시: 적절히 상세하게 (300-500 단어)
  - 코드 스니펫, 다이어그램, 예제 적극 활용

# Interaction Trigger
- If I ask for a feature implementation, assume the workflow above (Code -> Test -> Todo -> Devlog) applies unless told otherwise.
- When a **Phase is completed**, automatically write a comprehensive devlog in STAR format without being asked.