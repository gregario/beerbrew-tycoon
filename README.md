# BeerBrew Tycoon

A brewery management sim where you build a beer empire from your garage, with roguelite meta-progression between runs.

Inspired by Game Dev Tycoon. Built with Godot 4 for Steam.

## Status

**Pre-spec phase.** Product thinking is captured in `reference/`. Next step: run `/opsx:propose` to create proper OpenSpec-managed specs.

## Project Structure

```
beerbrew-tycoon/
  CLAUDE.md              # Project AI instructions
  README.md              # This file
  .gitignore
  reference/             # Initial product thinking (pre-OpenSpec)
  src/                   # Source code (Godot project)
  tests/                 # Tests
  openspec/              # Specs managed by OpenSpec
  .claude/               # OpenSpec + Superpowers skills
```

## Workflow

1. **Spec mode** — Use OpenSpec (`/opsx:propose`) to define and evolve specs
2. **Execution mode** — Use Superpowers to implement with TDD and code review
3. Small iterations and bug fixes go through Superpowers directly
4. New features go through OpenSpec first
