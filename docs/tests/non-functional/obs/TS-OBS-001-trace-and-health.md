---
id: TS-OBS-001
title: Trace id propagation and health endpoints
level: integration
covers: [NFR-OBS-001]
status: automated
automated_in: [src/test/ridgun/test_socket.rg]
---
# TS-OBS-001
1. Request with `X-Trace-Id: abc` to a failing endpoint → log line contains `abc`; error envelope `trace_id == "abc"`.
2. `/healthz` → 200 with persistence down; `/readyz` → 503 with persistence down, 200 when up.
