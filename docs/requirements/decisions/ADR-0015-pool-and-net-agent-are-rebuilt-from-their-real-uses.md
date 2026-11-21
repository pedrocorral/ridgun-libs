---
id: ADR-0015
title: pool and net_agent are rebuilt from the programs that need them
status: accepted
date: 2026-11-21
supersedes: []
affects: [FR-POOL-001, FR-NETAGENT-001, FR-POSIX-005, FR-AGENT-001, API-POOL-001, API-NETAGENT-001, API-AGENT-001, DM-Pool, DM-NetAgent, src/main/ridgun/lib/pool.ridgun, src/main/ridgun/lib/net_agent.ridgun, src/main/ridgun/lib/posix.ridgun, src/test/ridgun/test agent.ridgun, docs/book]
---
# ADR-0015 — `pool` and `net_agent` are rebuilt from the programs that need them

**Accepted by the user on 2026-11-21**, together with `FR-POOL-001`, `FR-NETAGENT-001` and `FR-POSIX-005`. The API contracts and data models stay in draft until the code confirms their signatures.

## Context
- `pool` and `net_agent` are specified inside `FR-AGENT-001`. `pool` routes a message by key over a list of agents. `net_agent` pairs one descriptor with one agent and writes each reply in one go.
- No program imports either lib. Only `test agent.ridgun` does.
- Three programs wrote by hand what these libs are named after:
  - Solstice's HTTP server (its ADR-0014): 1 to 64 worker agents, each with its own database session; the job goes to the first idle worker; a pipe wakes the accept loop when a worker ends; nothing is accepted while all are busy; one client address may hold only some of the workers.
  - Eterval's server (its ADR-0011): one loop over a table of connections, each with an input buffer and an output buffer; complete requests are parsed from the buffer; a client whose unsent output passes 64 MB is closed. The loop wakes 1 000 times a second because `posix` waits on one descriptor only.
  - Vonkeep's gate: the same loop, with a limit of time for the handshake, a limit of connections and its own wait on many descriptors (`lk_wait_io`).
- Fixing defects in the two libs one by one (2026-11-21: a blocking write, the empty pool) added behaviour that no program had asked for.

## Options considered
1. Leave the libs as they are, with their limits written down.
2. Remove both libs.
3. Rebuild them from the three programs, and prove them by moving one of those programs onto them.

## Decision
Option 3.
- `pool` becomes the bounded pool of worker agents of Solstice (`FR-POOL-001`). Routing by key stays as it is (AC8), although no program uses it.
- `net_agent` becomes the loop of Eterval and Vonkeep (`FR-NETAGENT-001`). An agent per connection is no longer what the lib is: the state of a connection is whatever the application chooses.
- `posix` gains one wait on many descriptors (`FR-POSIX-005`), which the loop needs.
- A prototype answered the one open question of the pool: a lib can wrap any worker function of type `(S J => (S, R))`, keep the worker's state between jobs and write the worker's number to a pipe when the job ends (two workers, three jobs, results in the order they ended). The prototype is not in the repository.

## Consequences
- Requirements to update: when `FR-POOL-001` and `FR-NETAGENT-001` are implemented, `FR-AGENT-001` loses the parts about `pool` and `net_agent` (its AC4 and AC5 and their constraints), and `API-AGENT-001` loses their signatures. `API-POSIX-001` gains the wait of `FR-POSIX-005`.
- Tests to update: `TS-POOL-001` and `TS-NETAGENT-001` are written from the acceptance criteria once the requirements are approved; the steps 6 to 8 of `TS-AGENT-001` move to them.
- Code to update: `pool.ridgun`, `net_agent.ridgun`, `posix.ridgun`. `ConnSlot`, `conn poll step`, `reactor sweep` and `reactor shutdown` leave `net_agent`.
- Proof: Solstice's worker pool moves onto `pool`, and Eterval's loop onto `net_agent`. Each lib is done when its program passes its own tests on it.
- The book: chapters 31 and 32 are regenerated from the new code.
