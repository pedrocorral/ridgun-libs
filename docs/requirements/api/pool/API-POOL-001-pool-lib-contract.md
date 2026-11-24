---
id: API-POOL-001
title: Public lib contract for pool (pool.ridgunlib)
status: approved
implements: [FR-POOL-001]
auth: none
---
# API-POOL-001 — Public lib contract for `pool` (`pool.ridgun`)

## Request
- Imported via `import pool`.
- Worker pool (`FR-POOL-001` AC1 to AC7). `S` is the state of a worker, `J` a job, `R` its result:
  - `type WorkerPool S J R` (fields private, see `DM-Pool`)
  - `type PoolDone R = PoolDone Int String R`: `slot_index`, `job_tag`, result
  - `pool start Int (S J => (S, R)) S => WorkerPool S J R`: `worker_count`, the worker function, the first state of every worker
  - `pool capacity (WorkerPool S J R) => Int`
  - `pool busy (WorkerPool S J R) => Int`
  - `pool idle (WorkerPool S J R) => Int`
  - `pool submit (WorkerPool S J R) J String => Int (WorkerPool S J R)`: the job and its `job_tag` (`""` for none); the answer is the `slot_index` that took it, or `-1` when it was refused, and the pool to use from now on
  - `pool tagged (WorkerPool S J R) String => Int`: busy workers whose job has that `job_tag`
  - `pool done fd (WorkerPool S J R) => Int`: the descriptor that is readable when a job has ended
  - `pool collect (WorkerPool S J R) Int => [PoolDone R] (WorkerPool S J R)`: `timeout_ms` to wait for the first job to end (`0`: do not wait)
  - `pool refused (WorkerPool S J R) => Int`: jobs refused since the start
  - `pool with waiting (WorkerPool S J R) Int => WorkerPool S J R`: room for `wait_max` jobs to wait when every worker is busy (a pool starts with `0`)
  - `pool submit or wait (WorkerPool S J R) J String => Int (WorkerPool S J R)`: as `pool submit` with an idle worker; with every worker busy the job waits if there is room (the answer is `-2`) or is refused (`-1`). It never waits itself. The jobs that wait go to the workers as they end, in the order they came
  - `pool waiting (WorkerPool S J R) => Int`: the `waiting_count`
  - `pool drain (WorkerPool S J R) Int => [PoolDone R] (WorkerPool S J R)`: `timeout_ms` to wait for the jobs in flight; then every worker is stopped
- Routing by key over a list of agents (`FR-POOL-001` AC8):
  - `type AgentPool = Pool Int [Agent]`
  - `pool of [Agent] => AgentPool`
  - `pool size AgentPool => Int`: the number of agents in the list
  - `pool is empty AgentPool => Bool`
  - `pool agents AgentPool => [Agent]`
  - `pool ask shard AgentPool Int A => B`
  - `pool ask shard or AgentPool Int A B => B`: the last argument is the answer for a list with no agents
  - `pool broadcast AgentPool A => ()`
  - `pool drain all AgentPool => [B]`
  - `pool shutdown AgentPool => ()`

## Responses
| Code | When | Body |
|---|---|---|
| `WorkerPool S J R` | `start`; second of the pair of `submit`, `collect`, `drain` | The pool to use from now on |
| `Int` `>= 0` | `submit` | The worker that took the job |
| `-1` | `submit` | Every worker is busy, or the pool is draining or stopped: the job was not taken |
| `[PoolDone R]` | `collect`, `drain` | One entry per job that ended, each exactly once |
| `[]` | `collect` | No job ended within `timeout_ms` |

## Rules
- Every exported function starts with `pool `.
- The worker function has the type `(S J => (S, R))`: it gets the state its previous job returned and returns the next state with the result. Inside a `type` the pair is written `(S, R)` (ridgunc 1.0.46 does not read `S R` there).
- The caller uses the pool an operation returns and does not keep the old one.
- One thread, the caller's, talks to the workers (`FR-POOL-001`, Constraints).
- `pool start` with fewer than 1 worker starts 1; with more than 64, 64.
- After `pool drain` the pool takes no jobs: `pool submit` and `pool submit or wait` answer `-1`.
- `pool submit` never lets a job wait. `pool drain` also runs the jobs that wait, until its time ends; one that still waits then is not run.
- A worker function is passed by its name in parentheses: `pool start 3 (my work) 0`.
- `pool submit`, `pool collect` and `pool drain` answer a pair: the result first, the pool second (`k, p1 = pool submit p0 job ""`). ridgunc 1.0.55 in strict mode refuses an output that starts with a type in parentheses.
- As a parameter a pool is written with its three types in parentheses: `(WorkerPool Int Int Int)`; a list of results, `[(PoolDone Int)]`.
- `pool capacity` of a drained pool is `0`, and its `pool done fd` is `-1`.
- The worker writes its number to the pipe before its result can be received; `pool collect` reads the numbers and receives exactly those results.
