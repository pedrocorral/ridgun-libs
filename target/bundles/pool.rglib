-- ============================================================
-- src/main/ridgun/lib/pool.rg
-- Pure-Ridgun Sharded & Round-Robin Agent Pools Library (AGENT)
-- @implements FR-AGENT-001
-- @implements API-AGENT-001
-- @implements DM-Agent
-- @mitigates VUL-INPUT-001
-- ============================================================

module :: pool

type AgentPool = Pool Int [Agent]

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: pool size AgentPool   => Int
      pool size (Pool sz _) =  sz

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: pool agents AgentPool    => [Agent]
      pool agents (Pool _ ags) =  ags

-- Look up the i-th agent in a pool (0-indexed)
-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: pool get agent [Agent]  Int => Agent
      pool get agent (ag:_)   0   =  ag
      pool get agent (_:rest) idx =  pool get agent rest (idx - 1)

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: pool abs Int => Int
      pool abs x
        | x < 0     = 0 - x
        | otherwise = x

-- Route a message to a deterministic shard `key_hash % size` and return the reply via `ask`
-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: pool ask shard AgentPool Int A => B
      pool ask shard (Pool size agents) key_hash msg =
        (pool abs key_hash) % size -> shard_idx
        pool get agent agents shard_idx -> target_ag
        ask target_ag msg

-- Broadcast a message to every agent in the pool (e.g. configuration reload or tick)
-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: pool broadcast AgentPool       A   => ()
      pool broadcast (Pool _ agents) msg =  pool broadcast list agents msg

fn :: pool broadcast list [Agent]   A   => ()
      pool broadcast list []        _   =  ()
      pool broadcast list (ag:rest) msg =
        send msg to ag
        pool broadcast list rest msg

fn :: pool drain ready Agent => [B]
      pool drain ready ag    =  pool drain ready loop ag []

fn :: pool drain ready loop Agent [B] => [B]
      pool drain ready loop ag acc =
        pool drain step ag (try receive from ag) acc

fn :: pool drain step Agent Option [B] => [B]
      pool drain step _ None acc = acc
      pool drain step ag (Some r) acc = pool drain ready loop ag (acc :: [r])

-- Drain all ready responses across all shards in the pool (non-blocking)
-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: pool drain all AgentPool       => [B]
      pool drain all (Pool _ agents) =  pool drain list agents []

fn :: pool drain list [Agent]   [B] => [B]
      pool drain list []        acc =  acc
      pool drain list (ag:rest) acc =
        ag pool drain ready -> ready
        pool drain list rest (acc :: ready)

fn :: pool stop list [Agent]   => ()
      pool stop list []        =  ()
      pool stop list (ag:rest) =
        stop ag
        pool stop list rest

-- Stop all agents in the pool and reclaim their isolated state
-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: pool shutdown AgentPool       => ()
      pool shutdown (Pool _ agents) =  pool stop list agents
