---
id: DM-Pool
title: Worker pool and the jobs it has in flight
status: draft
related: [FR-POOL-001, API-POOL-001, ADR-0015, DM-Agent]
---
# DM-Pool — Worker pool and the jobs it has in flight

## Fields
| Field | Type | Constraints | Notes |
|---|---|---|---|
| worker_count | Int | `1..64` | Fixed when the pool starts |
| slot_index | Int | `0 .. worker_count - 1` | One worker; its agent holds the worker's state |
| job_tag | String | `""` when the worker is idle or the job had no tag | The tag of the job a worker is running |
| busy_count | Int | `0 .. worker_count` | Workers running a job |
| done_fd | Int | `>= 0` while the pool runs | Read end of the pipe a worker writes its `slot_index` to when its job ends |
| refused_count | Int | `>= 0` | Jobs refused since the start |

## Relations
- Each worker is a stateful agent of `DM-Agent`. Its state has the type the caller chose and the pool never reads it.

## Invariants
- A worker runs at most one job at a time.
- `busy_count` is the number of workers whose job has been handed out and not collected.
- One byte is written to the pipe per job that ends, and its result is ready to be received when the byte is there.
- Only the thread of the caller sends to the workers and receives from them.

## Lifecycle
- Started by `pool start`; workers go from idle to busy with `pool submit` and back with `pool collect`; `pool drain` stops the workers and closes the pipe, and the pool takes no more jobs.
