---
id: FR-POOL-001
title: Run jobs on a bounded pool of worker agents that keep their own state
type: functional
status: approved
priority: must
domain: POOL
depends_on: [FR-AGENT-001, FR-POSIX-001]
related: [API-POOL-001, DM-Pool, ADR-0015, FR-POSIX-005, VUL-INFRA-002, VUL-INPUT-001]
tests: []
---
# FR-POOL-001 — Run jobs on a bounded pool of worker agents that keep their own state

## Statement
The `pool` lib SHALL run jobs on a fixed number of worker agents, each with its own state, hand every job to an idle worker or refuse it, and tell the caller when a job ends without the caller polling.

## Rationale
This is the pool Solstice wrote by hand in its HTTP server (Solstice ADR-0014): N workers, each owning one database session, an accept loop that stops accepting when all are busy, a pipe that wakes the loop when a worker ends, and a cap on how many workers one client may hold. A lib gives the same to every server, tested once. The `pool` lib of today routes by key only, and no program uses it.

## Acceptance criteria
- AC1: Given a pool started with `n` workers and a first state, when jobs are submitted, then at most `n` jobs run at the same time, each worker starts from that first state, and each worker gets back, in every job, the state its previous job returned. No worker ever sees the state of another.
- AC2: Given a pool with an idle worker, when a job is submitted, then an idle worker takes it and the pool counts that worker as busy. Given a pool where every worker is busy, when a job is submitted, then the pool refuses it at once and says so; it never waits and never queues it.
- AC3: Given jobs in flight, when a worker ends its job, then a descriptor of the pool becomes readable, so the caller can wait on it together with its own descriptors. Collecting then returns the result of that job, with the worker that ran it and the tag it was submitted with, and that worker is idle again.
- AC4: Given that no job has ended, when the caller collects with no waiting time, then it gets no results at once. With a waiting time it waits at most that time for the first job to end.
- AC5: Given jobs submitted with a tag (for example the address of a client), when the caller asks how many busy workers hold that tag, then the pool answers that number, so the caller can keep one client from holding every worker.
- AC6: Given several jobs in flight, when they end in any order, then every result is returned exactly once and with its own job: a result never reaches another job.
- AC7: Given jobs in flight, when the pool is drained with a time limit, then it accepts no more jobs, waits for those in flight for at most that time, returns their results, stops every worker and closes its descriptors.
- AC8: Given a list of agents and a key, when a message is routed by key (`pool ask shard`), then it reaches agent `abs(key) % n`, the same key always reaches the same agent, a negative key is valid, `pool broadcast` reaches every agent, `pool drain all` returns the replies that are ready without blocking, and `pool shutdown` stops every agent. (Moved from `FR-AGENT-001` AC4; no program uses it today.)

## Actors & permissions
- Any Ridgun program or lib importing `pool`.

## Constraints & edge cases
- A pool has from 1 to 64 workers. A request for fewer than 1 gives 1; a request for more than 64 gives 64.
- A worker's state is created by the caller and is opaque to the pool (a database session, a counter, nothing).
- The pool does not queue: the caller decides what a refused job means (wait, answer "busy", leave it in the kernel's backlog).
- Routing by key on a list with no agents: `pool ask shard or` returns the default it was given; `pool ask shard` stops the program with the message `pool ask shard: the pool has no agents`.
- A reply of an agent used from several threads can reach the wrong one (measured in Solstice ADR-0014 on ridgunc 0.9.30). The pool therefore talks to each worker from one thread only, the caller's.

## Data & privacy
- The pool keeps no data of its own beyond the tag of each job in flight. See `DM-Pool`.

## Security & observability notes
- `VUL-INFRA-002`: the number of jobs running at once is bounded, and the tag count lets a server bound them per client.
- The number of workers, of busy workers and of jobs refused are available for a server's metrics.

## Out of scope
- A queue of waiting jobs, work stealing and balancing by load.
- Restarting a worker whose function fails.
- Pools of resources that are not the state of a worker.
