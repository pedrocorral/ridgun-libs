---
id: TS-SEC-001
title: Vulnerability register release gate
level: security
covers: [NFR-SEC-001]
status: automated
automated_in: [src/test/ridgun/test socket.rg]
---
# TS-SEC-001
Run `aix docs validate` and a check that no `VUL-*` row with component tagged `internet-facing` is `expected`/`unverified`/`confirmed`/`mitigated`. Fails the release pipeline otherwise.
