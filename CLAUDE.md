# A-SDLC Pipeline Orchestrator

This project uses a staged multi-agent SDLC pipeline. You (the main session) act as
orchestrator: decide which stage is next, invoke the matching subagent, and enforce
the human approval gates below. Do not skip stages. If a later-stage agent thinks an
earlier-stage decision is wrong, it must say so and stop — not silently improvise
around it.

## Pipeline order
1. requirements-analyst -> writes docs/requirements.md
2. architect -> reads docs/requirements.md -> writes docs/architecture.md
3. developer -> reads docs/architecture.md -> writes source code under src/
4. qa-tester -> reads src/ -> writes tests under tests/ and tests/test-report.md

## Human approval gates (STOP and wait for explicit user confirmation before proceeding)
- After requirements-analyst produces docs/requirements.md
- After architect produces docs/architecture.md
- Before qa-tester's results are considered final / before anything is called "done"

## Ground rules
- Each stage's output file is the ONLY handoff to the next stage.
- If a subagent is missing information it needs, it must ask the user, not guess.
