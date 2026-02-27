# BeerBrew Tycoon — Project Instructions

This is a project inside the AI-Factory workspace. It follows the spec-driven workflow defined in the parent CLAUDE.md.

## Product Summary

A brewery management sim inspired by Game Dev Tycoon, with roguelite meta-progression between runs. Built with Godot 4 for Steam.

See `reference/product.md` and `reference/mvp.md` for the initial product thinking that should be fed into OpenSpec when creating the first specs.

## Workflow Overview

- **OpenSpec** — Product thinking. Creates specs, designs changes, manages the product lifecycle.
- **Superpowers** — Engineering. Implements tasks with TDD, code review, and subagent execution.

## Spec Mode (OpenSpec)

Use OpenSpec for:
- Defining product specs (first run: feed content from `reference/` into `/opsx:propose`)
- Proposing new features or large enhancements
- Reviewing and updating specs after Superpowers iterations

Key commands:
- `/opsx:propose "idea"` — Propose a change with proposal, design, specs, and tasks.
- `/opsx:explore` — Review the current state of specs.
- `/opsx:apply` — Implement an approved change.
- `/opsx:archive` — Archive a completed change and update master specs.

### Spec Sync Rule

Before proposing new features, OpenSpec must review the current codebase to update its understanding. Code may have evolved through Superpowers iterations since the last spec was written.

## Execution Mode (Superpowers)

Use Superpowers for:
- Implementing tasks from OpenSpec proposals
- Small enhancements and iterations
- Bug fixes and refactoring

Superpowers activates automatically and enforces TDD, systematic debugging, and code review.

## When to Use Which

| Situation | Tool |
|---|---|
| New feature or large enhancement | OpenSpec → Superpowers |
| Small enhancement or iteration | Superpowers |
| Bug fix | Superpowers |
| Specs and code have diverged | OpenSpec (sync first) |

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
- 45/45 GUT tests passing (`make test`).
- Godot binary (Steam): `/Users/gregario/Library/Application Support/Steam/steamapps/common/Godot Engine/Godot.app/Contents/MacOS/Godot`
- Manual tasks outstanding: 14.6 (60fps profiler check), 14.7 (pixel aliasing at 1080p).

## Development Rules

1. Never write code before specs exist. Use OpenSpec to create them.
2. All source code goes in `src/`.
3. All tests go in `src/tests/`. Run `make test` after every change.
4. Work in small iterative commits.
5. Always read the Godot stack profile before implementing.

## Reference Material

- `reference/product.md` — Product definition, core concept, game mechanics
- `reference/mvp.md` — MVP scope, user flow, acceptance criteria
