# Lightweight Linux Distribution — AI Project Kit

This kit contains the operating instructions and phased roadmap for building a source-based lightweight x86_64 Linux distribution.

## Files

- `AI_MASTER_PROMPT.md` — permanent role, rules, architecture constraints, safety boundaries, and reporting requirements for the AI agent.
- `IMPLEMENTATION_ROADMAP.md` — phases, tasks, deliverables, and acceptance gates.
- `PHASE_PROMPTS.md` — copy/paste prompts to execute one phase at a time.
- `PROJECT_STATUS_TEMPLATE.md` — initial status and implementation log template.

## How to use

1. Create/open the local project directory.
2. Copy these files into its root.
3. Give the agent `AI_MASTER_PROMPT.md` and `IMPLEMENTATION_ROADMAP.md` as project context.
4. Start with the “First message — initialize the project” prompt from `PHASE_PROMPTS.md`.
5. Review the agent's report and diff before approving the next phase.
6. Do not ask the agent to implement every phase in one request.

The agent must work locally, preserve uncommitted work, and must not commit/push or touch physical disks without explicit permission.
