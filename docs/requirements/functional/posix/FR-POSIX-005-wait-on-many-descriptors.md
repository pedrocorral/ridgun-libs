---
id: FR-POSIX-005
title: Wait until one of many descriptors is ready
type: functional
status: implemented
priority: must
domain: POSIX
depends_on: [FR-POSIX-001]
related: [API-POSIX-001, FR-NETAGENT-001, FR-POOL-001, VUL-INFRA-002]
tests: [TS-POSIX-005]
---
# FR-POSIX-005 — Wait until one of many descriptors is ready

## Statement
The `posix` lib SHALL wait until at least one descriptor of a set is ready to read or to write, or until a time limit ends, and say which ones are ready.

## Rationale
A program that serves many connections needs one wait for all of them. Today `posix` waits on one descriptor only. Eterval's loop wakes about 1 000 times a second for that reason (its ADR-0011, asked from ridgun-libs on 2026-11-07), and Vonkeep wrote its own wait (`lk_wait_io`).

## Acceptance criteria
- AC1: Given a list of descriptors to read and a list of descriptors to write, when one of them becomes ready before the time limit, then the call returns at once and names every descriptor that is ready.
- AC2: Given that no descriptor is ready, when the time limit ends, then the call returns an empty answer. A limit of `0` returns at once.
- AC3: Given a descriptor that is closed, invalid or in error, when the call runs, then that descriptor is named as failed and the others are still answered.
- AC4: Given a listening socket, a signal descriptor (`sys signal watch`) and connected sockets in the same call, then each is answered as any other descriptor.
- AC5: Given 1 024 descriptors in one call, then the call answers correctly.

## Actors & permissions
- Any Ridgun program or lib importing `posix`.

## Constraints & edge cases
- Both lists may be empty: the call then only waits for the time limit.
- A descriptor may be in both lists.
- The call does not read or write: it only reports.

## Data & privacy
- None.

## Security & observability notes
- `VUL-INFRA-002`: a server that waits on all its descriptors at once does not need a busy loop, and can apply its limits in every turn.

## Out of scope
- Edge-triggered notification and descriptor sets kept in the kernel between calls.
