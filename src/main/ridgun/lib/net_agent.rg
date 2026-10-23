-- ============================================================
-- src/main/ridgun/lib/net_agent.rg
-- Pure-Ridgun Per-Connection Stateful Agent Reactor Library (AGENT)
-- @implements FR-AGENT-001
-- @implements API-AGENT-001
-- @implements DM-Agent
-- @mitigates VUL-INPUT-001
-- ============================================================

type ConnSlot = ConnSlot Int Agent

type StepOutcome = ConnKeep ConnSlot String | ConnClosed

-- Poll a single connection fd (non-blocking, timeout = 0) and route incoming data to its Agent
-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: conn poll step ConnSlot         => StepOutcome
      conn poll step (ConnSlot fd ag) =
        ev = sys poll fd 1 0
        conn handle event fd ag ev

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: conn handle event Int Agent Int => StepOutcome
      conn handle event fd ag ev
        | ev < 0 =
          -- Poll error: close descriptor and stop agent
          _ = sys close fd
          stop ag
          ConnClosed
        | ev >= 8 =
          -- POLLERR (8) or POLLHUP (16): peer disconnected
          _ = sys close fd
          stop ag
          ConnClosed
        | ev == 0 =
          -- No new bytes to read; check if the agent has a queued async reply
      conn drain outbound fd ag (try receive from ag)
        | otherwise =
          -- POLLIN (1): read frame and forward to the connection's stateful agent
          payload = sys read fd fd 65536
          conn feed payload fd ag payload

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: conn feed payload Int Agent String => StepOutcome
      conn feed payload fd ag "" =
        -- EOF on socket: close descriptor and stop agent deterministically
        _ = sys close fd
        stop ag
        ConnClosed
      conn feed payload fd ag data =
        send data to ag
        conn drain outbound fd ag (try receive from ag)

fn :: conn cast str A => String
      conn cast str x =  x

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: conn drain outbound Int Agent Option => StepOutcome
      conn drain outbound fd ag None = ConnKeep (ConnSlot fd ag) ""
      conn drain outbound fd ag (Some resp) =
        s = conn cast str resp
        _ = sys write fd fd s
        ConnKeep (ConnSlot fd ag) s

-- Sweep an entire connection table, pruning closed connections and keeping active ones
-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: reactor sweep [ConnSlot]  => [ConnSlot]
      reactor sweep []          =  []
      reactor sweep (slot:rest) =
        reactor sweep next (conn poll step slot) (reactor sweep rest)

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: reactor sweep next StepOutcome       [ConnSlot] => [ConnSlot]
      reactor sweep next ConnClosed        kept       =  kept
      reactor sweep next (ConnKeep slot _) kept       =  [slot] :: kept

-- Gracefully close all sockets and stop all connection agents on server shutdown
-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: reactor shutdown [ConnSlot] => ()
      reactor shutdown []         =  ()
      reactor shutdown ((ConnSlot fd ag):rest) =
        _ = sys close fd
        stop ag
        reactor shutdown rest
