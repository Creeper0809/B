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
- **Structure Requirement**:
  1. **Implementation**: Briefly explain what code was changed or added with details. Use code snippets if necessary.
  2. **Challenges & Troubleshooting (Crucial)**:
     - Describe specific difficulties (e.g., parsing ambiguity, logic errors).
     - Detail debugging steps taken.
     - Explain how the problem was resolved.
  3. **Final Logic Explanation**:
     - Provide a technical explanation of how the implemented feature works.
     - Mention architectural decisions.

# Interaction Trigger
- If I ask for a feature implementation, assume the workflow above (Code -> Test -> Todo -> Devlog) applies unless told otherwise.