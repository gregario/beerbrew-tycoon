# beerbrew-tycoon/CLAUDE.md — Project Rules (Design Required)

This project follows AI-Factory's Spec → Design → Execution workflow.

## Product Summary

A brewery management sim inspired by Game Dev Tycoon, with roguelite meta-progression between runs. Built with Godot 4 for Steam.

See `reference/product.md` and `reference/mvp.md` for the initial product thinking.

## Workflow

Spec Mode (OpenSpec) → Design Mode → Execution Mode (Superpowers).

Do NOT use `/opsx:apply` to implement tasks in this project. Use Superpowers instead.

### Design Mode Requirements

Before implementing any task that touches UI or scenes, Design Mode deliverables must exist:

1. `design/wireframes/<task>.md` — layout + notes
2. `design/mockups/<task>.png` or `.tscn` — annotated mockup
3. `design/theme.json` — project theme tokens (already created)

Once deliverables are approved, switch to Execution Mode and invoke Superpowers.

### Spec Mode (OpenSpec)

Use OpenSpec for:
- Defining product specs
- Proposing new features or large enhancements
- Reviewing and updating specs after Superpowers iterations

Key commands:
- `/opsx:propose "idea"` — Propose a change with proposal, design, specs, and tasks.
- `/opsx:explore` — Review the current state of specs.
- `/opsx:archive` — Archive a completed change and update master specs.

### Spec Sync Rule

Before proposing new features, OpenSpec must review the current codebase to update its understanding. Code may have evolved through Superpowers iterations since the last spec was written.

### Execution Mode (Superpowers)

Use Superpowers for:
- Implementing tasks from OpenSpec proposals
- Small enhancements and iterations
- Bug fixes and refactoring

## Stack Profile

This project uses the **Godot 4 stack profile**.

Before writing any code, read: `../../stacks/godot/STACK.md`

| File | Read When |
|------|-----------|
| `stacks/godot/project_structure.md` | Creating files or scenes |
| `stacks/godot/coding_standards.md` | Writing GDScript |
| `stacks/godot/testing.md` | Writing or running tests |
| `stacks/godot/performance.md` | Optimising |
| `stacks/godot/pitfalls.md` | Debugging unexpected behaviour |

## Project State

- MVP complete. OpenSpec change `define-product-core` archived 2026-02-27.
- OpenSpec change `godot-stack-refactor` in progress — tasks ready for Design Mode → Execution.
- 45/45 GUT tests passing (`make test`).
- Godot binary (Steam): `/Users/gregario/Library/Application Support/Steam/steamapps/common/Godot Engine/Godot.app/Contents/MacOS/Godot`
- Manual tasks outstanding: 14.6 (60fps profiler check), 14.7 (pixel aliasing at 1080p), 6.1–6.5 (UI folder restructure via Godot editor).

## Development Rules

1. Do not implement code until Design Mode deliverables exist for the task.
2. All source code goes in `src/`.
3. All tests go in `src/tests/`. Run `make test` after every change.
4. Work in small iterative commits.
5. Always read the Godot stack profile before implementing.

## Reference Material

- `reference/product.md` — Product definition, core concept, game mechanics
- `reference/mvp.md` — MVP scope, user flow, acceptance criteria
