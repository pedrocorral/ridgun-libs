---
id: TASK-0025
title: Implement jwt.rg (RFC 7519 HS256 & AEAD tokens) and ws.rg (RFC 6455 WebSocket) libraries
status: completed
priority: must
owner: agent-001
implements: [FR-JWT-001, API-JWT-001, DM-Jwt, FR-WS-001, API-WS-001, DM-WebSocket]
tests: [TS-JWT-001, TS-WS-001]
mitigates: [VUL-AUTHN-001, VUL-INPUT-001]
depends_on: []
scope:
  - src/main/ridgun/lib/jwt.rg
  - src/main/ridgun/lib/ws.rg
  - src/test/ridgun/test jwt.rg
  - src/test/ridgun/test ws.rg
  - build.rg
context_files:
  - docs/requirements/functional/jwt/FR-JWT-001-jwt-hs256-and-aead-tokens.md
  - docs/requirements/functional/ws/FR-WS-001-rfc6455-websocket-handshake-and-framing.md
claimed: 2026-10-23T20:30:27Z
claimed_by: agent gemini@solarfall
---
# TASK-0025 — Implement `jwt.rg` (RFC 7519 HS256 & AEAD tokens) and `ws.rg` (RFC 6455 WebSocket) libraries

## Goal
Implement pure-Ridgun `jwt.rg` and `ws.rg`, their test suites (`test jwt.rg`, `test ws.rg`), and `.rglib`/`.so` bundles.
