-- ============================================================
-- src/main/ridgun/lib/agent.rg
-- Pure-Ridgun Native Agent Concurrency, Lifecycle, Messaging & Stateful Actors Library (AGENT)
-- @implements FR-AGENT-001
-- @implements API-AGENT-001
-- @implements DM-Agent
-- @mitigates VUL-INPUT-001
-- ============================================================

type AgentStatus = AgentRunning | AgentStopped | AgentTimedOut Int | AgentFailed String
type AgentReply  = ReplyInt Int | ReplyStr String | ReplyBool Bool | ReplyEmpty | ReplyStopped | ReplyTimeout Int | ReplyError String
type CounterState = cnt_val: Int
type KvCmd        = KvPut String String | KvGet String | KvDel String | KvHas String | KvCount | KvKeys | KvClear
type KvEntry      = kv_k: String, kv_v: String
type KvState      = kv_size: Int, kv_items: [KvEntry]
type LogState     = log_sep: String, log_buf: String

-- ── Status & Reply Formatting ────────────────────────────────

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
-- @implements DM-Agent
fn :: format agent status AgentStatus        => String
      format agent status AgentRunning       =  "running"
      format agent status AgentStopped       =  "stopped"
      format agent status (AgentTimedOut ms) =  "timeout after {ms} ms"
      format agent status (AgentFailed   msg) = "failed: {msg}"

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
-- @implements DM-Agent
fn :: format agent reply AgentReply        => String
      format agent reply (ReplyInt     n)  =  int to str n
      format agent reply (ReplyStr     s)  =  s
      format agent reply (ReplyBool True)  =  "true"
      format agent reply (ReplyBool False) =  "false"
      format agent reply ReplyEmpty        =  "agent outbox empty"
      format agent reply ReplyStopped      =  "agent stopped"
      format agent reply (ReplyTimeout ms) =  "agent timeout after {ms} ms"
      format agent reply (ReplyError  msg) =  "agent error: {msg}"

-- ── Lifecycle Inspection & Control (`is agent alive`, `agent status`, `stop agent`, `agent stop all`) ──

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: is agent alive (Agent A B) => Bool
      is agent alive ag          =  agent alive ag

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: agent status (Agent A B) => AgentStatus
      agent status ag          =
        | agent alive ag = AgentRunning
        | otherwise      = AgentStopped

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: stop agent (Agent A B) => AgentStatus
      stop agent ag          =
        _ = stop ag
        AgentStopped

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: agent stop all [Agent]   => ()
      agent stop all []        =  ()
      agent stop all (ag:rest) =
        stop ag
        agent stop all rest

-- ── Core Combinators (`agent ask`, `agent try ask`, `agent send batch`, `agent receive count`, `agent map batch`, `agent drain ready`) ──

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: agent ask Agent A   => B
      agent ask ag    msg =  ask ag msg

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: agent try ask Agent A   => Option
      agent try ask ag    msg =
        send msg to ag
        try receive from ag

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: agent send batch Agent [A]      => ()
      agent send batch _     []       =  ()
      agent send batch ag    (m:rest) =
        send m to ag
        agent send batch ag rest

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: agent receive count Agent Int   => [B]
      agent receive count ag    count =  agent receive count loop ag count []

fn :: agent receive count loop Agent Int [B] => [B]
      agent receive count loop ag count acc
        | count <= 0 = acc
        | otherwise =
          r = receive from ag
          agent receive count loop ag (count - 1) (acc :: [r])

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: agent map batch Agent [A]  => [B]
      agent map batch ag    msgs =
        n = agent list len msgs 0
        _ = agent send batch ag msgs
        agent receive count ag n

fn :: agent list len [A]    Int => Int
      agent list len []     acc =  acc
      agent list len (_:xs) acc =  agent list len xs (acc + 1)

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: agent drain ready Agent => [B]
      agent drain ready ag    =  agent drain ready loop ag []

fn :: agent drain ready loop Agent [B] => [B]
      agent drain ready loop ag acc =
        agent drain step ag (try receive from ag) acc

fn :: agent drain step Agent Option [B] => [B]
      agent drain step _ None acc = acc
      agent drain step ag (Some r) acc = agent drain ready loop ag (acc :: [r])

-- ── Request-Reply & Non-Blocking Polling (`ask *`, `try poll *`, `ask * with timeout`) ──

fn :: ag cast opt A => B
      ag cast opt x =  x

fn :: ag unwrap try int (Option Int) => AgentReply
      ag unwrap try int (Some v)     =  ReplyInt v
      ag unwrap try int None         =  ReplyEmpty

fn :: ag unwrap try str (Option String) => AgentReply
      ag unwrap try str (Some s)        =  ReplyStr (ag cast opt s)
      ag unwrap try str None            =  ReplyEmpty

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
-- @mitigates VUL-INPUT-001
fn :: ask int (Agent Int Int) Int => AgentReply
      ask int ag              msg =
        | not (agent alive ag) = ReplyStopped
        | otherwise            =
          _ = send msg to ag
          ReplyInt (receive from ag)

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
-- @mitigates VUL-INPUT-001
fn :: ask str (Agent String String) String => AgentReply
      ask str ag                    msg    =
        | not (agent alive ag) = ReplyStopped
        | otherwise            =
          _ = send msg to ag
          ReplyStr (receive from ag)

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: try poll int (Agent A Int) => AgentReply
      try poll int ag            =
        | not (agent alive ag) = ReplyStopped
        | otherwise            = ag unwrap try int (try receive from ag)

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: try poll str (Agent A String) => AgentReply
      try poll str ag               =
        | not (agent alive ag) = ReplyStopped
        | otherwise            = ag unwrap try str (try receive from ag)

fn :: ag poll int step (Agent Int Int) (Option Int) Int Int => AgentReply
      ag poll int step ag (Some v) _ _ = ReplyInt v
      ag poll int step ag None deadline timeout_ms =
        | (sys time ms) >= deadline = ReplyTimeout timeout_ms
        | otherwise                 =
          _ = sys sleep ms 1
          ag wait int loop ag deadline timeout_ms

fn :: ag wait int loop (Agent Int Int) Int Int => AgentReply
      ag wait int loop ag deadline timeout_ms =
        | not (agent alive ag) = ReplyStopped
        | otherwise            = ag poll int step ag (try receive from ag) deadline timeout_ms

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
-- @mitigates VUL-INPUT-001
fn :: ask int with timeout (Agent Int Int) Int Int => AgentReply
      ask int with timeout ag msg timeout_ms =
        | not (agent alive ag) = ReplyStopped
        | timeout_ms <= 0      =
          _ = send msg to ag
          ag poll int step ag (try receive from ag) (sys time ms) 0
        | otherwise            =
          _ = send msg to ag
          ag wait int loop ag ((sys time ms) + timeout_ms) timeout_ms

fn :: ag poll str step (Agent String String) (Option String) Int Int => AgentReply
      ag poll str step ag (Some s) _ _ = ReplyStr (ag cast opt s)
      ag poll str step ag None deadline timeout_ms =
        | (sys time ms) >= deadline = ReplyTimeout timeout_ms
        | otherwise                 =
          _ = sys sleep ms 1
          ag wait str loop ag deadline timeout_ms

fn :: ag wait str loop (Agent String String) Int Int => AgentReply
      ag wait str loop ag deadline timeout_ms =
        | not (agent alive ag) = ReplyStopped
        | otherwise            = ag poll str step ag (try receive from ag) deadline timeout_ms

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
-- @mitigates VUL-INPUT-001
fn :: ask str with timeout (Agent String String) String Int => AgentReply
      ask str with timeout ag msg timeout_ms =
        | not (agent alive ag) = ReplyStopped
        | timeout_ms <= 0      =
          _ = send msg to ag
          ag poll str step ag (try receive from ag) (sys time ms) 0
        | otherwise            =
          _ = send msg to ag
          ag wait str loop ag ((sys time ms) + timeout_ms) timeout_ms

-- ── Batch Dispatch & Pipeline Relay (`ask batch *`, `relay *`) ──

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: ask batch int (Agent Int Int) [Int]    => [Int]
      ask batch int _               []       =  []
      ask batch int ag              (m:rest) =
        | not (agent alive ag) = []
        | otherwise            =
          _ = send m to ag
          r = receive from ag
          [r] :: (ask batch int ag rest)

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: ask batch str (Agent String String) [String] => [String]
      ask batch str _                     []       =  []
      ask batch str ag                    (m:rest) =
        | not (agent alive ag) = []
        | otherwise            =
          _ = send m to ag
          r = receive from ag
          [r] :: (ask batch str ag rest)

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: relay int (Agent Int Int) (Agent Int Int) Int => AgentReply
      relay int ag1             ag2             msg =
        | not (agent alive ag1) or not (agent alive ag2) = ReplyStopped
        | otherwise =
          _   = send msg to ag1
          mid = receive from ag1
          _   = send mid to ag2
          ReplyInt (receive from ag2)

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: relay str (Agent String String) (Agent String String) String => AgentReply
      relay str ag1                   ag2                   msg    =
        | not (agent alive ag1) or not (agent alive ag2) = ReplyStopped
        | otherwise =
          _   = send msg to ag1
          mid = receive from ag1
          _   = send mid to ag2
          ReplyStr (receive from ag2)

-- ── Stateful Counter Agent (`new counter agent`, `counter add`, `counter get`, `counter reset`) ──

fn :: ag counter step CounterState Int   => CounterState Int
      ag counter step st           delta =
        | delta == (0 - 999999999) = (CounterState 0, 0)
        | otherwise                =
          nxt = (cnt_val st) + delta
          (CounterState nxt, nxt)

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: new counter agent Int  => Agent Int Int
      new counter agent init =  agent (ag counter step) (CounterState init)

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: counter add (Agent Int Int) Int   => Int
      counter add ag              delta =
        | not (agent alive ag) = 0
        | otherwise            =
          _ = send delta to ag
          receive from ag

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: counter get (Agent Int Int) => Int
      counter get ag              =  counter add ag 0

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: counter reset (Agent Int Int) => Int
      counter reset ag              =  counter add ag (0 - 999999999)

-- ── Stateful Append-Only Log Agent (`new log agent`, `log append`, `log read`, `log clear`) ──

fn :: ag log join String String String => String
      ag log join cur sep entry =
        | (str len cur) == 0 = entry
        | otherwise          = cur + sep + entry

fn :: ag log step LogState String => LogState String
      ag log step st       cmd    =
        | cmd == "__READ__"  = (st, log_buf st)
        | cmd == "__CLEAR__" =
          st2 = st with log_buf: ""
          (st2, "")
        | otherwise =
          nb  = ag log join (log_buf st) (log_sep st) cmd
          st2 = st with log_buf: nb
          (st2, nb)

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: new log agent String => Agent String String
      new log agent sep    =  agent (ag log step) (LogState sep "")

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: log append (Agent String String) String => String
      log append ag                    entry  =
        | not (agent alive ag) = ""
        | otherwise            =
          _ = send entry to ag
          receive from ag

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: log read (Agent String String) => String
      log read ag                    =  log append ag "__READ__"

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: log clear (Agent String String) => String
      log clear ag                    =  log append ag "__CLEAR__"

-- ── Stateful In-Memory Key-Value Agent (`new kv agent`, `kv put`, `kv get`, `kv delete`, `kv has`, `kv count`, `kv keys`, `kv clear`) ──

fn :: ag kv lookup [KvEntry] String => String
      ag kv lookup []        _      =  ""
      ag kv lookup (e:rest)  key    =
        | (kv_k e) == key = kv_v e
        | otherwise       = ag kv lookup rest key

fn :: ag kv exists [KvEntry] String => Bool
      ag kv exists []        _      =  False
      ag kv exists (e:rest)  key    =
        | (kv_k e) == key = True
        | otherwise       = ag kv exists rest key

fn :: ag kv put list [KvEntry] String String => [KvEntry]
      ag kv put list [] key val = [KvEntry key val]
      ag kv put list (e:rest) key val =
        | (kv_k e) == key = [KvEntry key val] :: rest
        | otherwise       = [e] :: (ag kv put list rest key val)

fn :: ag kv del list [KvEntry] String => [KvEntry]
      ag kv del list [] _ = []
      ag kv del list (e:rest) key =
        | (kv_k e) == key = rest
        | otherwise       = [e] :: (ag kv del list rest key)

fn :: ag kv len [KvEntry] => Int
      ag kv len []        =  0
      ag kv len (_:rest)  =  1 + (ag kv len rest)

fn :: ag kv keys join String String => String
      ag kv keys join k rest_s =
        | (str len rest_s) == 0 = k
        | otherwise             = k + "," + rest_s

fn :: ag kv keys str [KvEntry] => String
      ag kv keys str []        =  ""
      ag kv keys str (e:rest)  =  ag kv keys join (kv_k e) (ag kv keys str rest)

fn :: ag kv has str Bool  => String
      ag kv has str True  =  "1"
      ag kv has str False =  "0"

fn :: ag kv next state KvState KvCmd => KvState
      ag kv next state st (KvPut key val) =
        p2 = ag kv put list (kv_items st) key val
        KvState (ag kv len p2) p2
      ag kv next state st (KvGet _) = st
      ag kv next state st (KvDel key) =
        p2 = ag kv del list (kv_items st) key
        KvState (ag kv len p2) p2
      ag kv next state st (KvHas _) = st
      ag kv next state st KvCount = st
      ag kv next state st KvKeys = st
      ag kv next state _ KvClear = KvState 0 []

fn :: ag kv next reply KvState KvCmd => String
      ag kv next reply _ (KvPut _   val) = val
      ag kv next reply st (KvGet key) = ag kv lookup (kv_items st) key
      ag kv next reply st (KvDel key) = ag kv lookup (kv_items st) key
      ag kv next reply st (KvHas key) = ag kv has str (ag kv exists (kv_items st) key)
      ag kv next reply st KvCount = int to str (kv_size st)
      ag kv next reply st KvKeys = ag kv keys str (kv_items st)
      ag kv next reply _ KvClear = ""

fn :: ag kv step KvState KvCmd => KvState String
      ag kv step st      cmd   =
        st2 = ag kv next state st cmd
        rep = ag kv next reply st cmd
        (st2, rep)

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: new kv agent => Agent KvCmd String
      new kv agent =  agent (ag kv step) (KvState 0 [])

fn :: ag kv call (Agent KvCmd String) KvCmd => String
      ag kv call ag                   cmd   =
        | not (agent alive ag) = ""
        | otherwise            =
          _ = send cmd to ag
          receive from ag

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: kv put (Agent KvCmd String) String String => String
      kv put ag                   key    val    =  ag kv call ag (KvPut key val)

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: kv get (Agent KvCmd String) String => String
      kv get ag                   key    =  ag kv call ag (KvGet key)

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: kv delete (Agent KvCmd String) String => String
      kv delete ag                   key    =  ag kv call ag (KvDel key)

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: kv has (Agent KvCmd String) String => Bool
      kv has ag                   key    =  (ag kv call ag (KvHas key)) == "1"

fn :: ag parse int String => Int
      ag parse int s      =
        | (str len s) == 0 = 0
        | otherwise        = str to int s

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: kv count (Agent KvCmd String) => Int
      kv count ag                   =  ag parse int (ag kv call ag KvCount)

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: kv keys (Agent KvCmd String) => String
      kv keys ag                   =  ag kv call ag KvKeys

-- @implements FR-AGENT-001
-- @implements API-AGENT-001
fn :: kv clear (Agent KvCmd String) => String
      kv clear ag                   =  ag kv call ag KvClear
