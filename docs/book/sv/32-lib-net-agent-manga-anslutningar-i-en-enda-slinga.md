# Kapitel 32: Lib:en `net_agent` — Många anslutningar i en enda slinga som inte väntar på någon

## 32.1. Varför finns lib:en `net_agent`? (Det verkliga problemet och Ridguns filosofi)

> *”Varför behöver jag en `net_agent`-lib skriven från grunden i ren Ridgun i stället för att bara länka in ett gammalt C-bibliotek?”*

Det är den första fråga varje systemingenjör ställer sig när man möter `net_agent`. Och svaret sammanfattar hela filosofin bakom `ridgun-libs`:

Låt oss vara ärliga: att acceptera TCP-anslutningar är den lätta delen av en server. Det svåra är klienten som skickar ett halvt meddelande, den som slutar läsa när du är skyldig den 60 MB och den som ansluter och inte säger något, alla på en gång och utan att någon av dem fördröjer de andra.

Lib:en **`net_agent`** är slingan i en server: `reactor start` skapar en tabell med anslutningar på en lyssnande socket, och varje `reactor turn` gör en enda väntan på den socketen, på alla anslutningar och på de deskriptorer du lägger till (en signaldeskriptor, deskriptorn för en arbetarpool), och accepterar, läser och skickar sedan utan att vänta på någon anslutning. Varje anslutning har en inbuffert som du tar hela meddelanden ur (`reactor input`, `reactor take`), en utkö (`reactor send`), ett eget tillstånd (`reactor state`) och en stängning efter sändning (`reactor close after send`); `reactor each` är det enkla fallet, en funktion som anropas för varje anslutning med indata; och `reactor stop` skickar det som står i kö och stänger allt. Det är slingan som Eterval och Vonkeep skrev för hand, var och en sin egen.

I ett traditionellt ekosystem innebär uppgifter inom domänen **`NETAGENT`** ofta att man drar in externa C-beroenden, brottas med råa pekare, ogenomskinliga typkonverteringar, okontrollerade undantag eller oförutsägbara skräpsamlarpauser. I Ridgun löser lib:en **`net_agent`** (`src/main/ridgun/lib/net_agent.ridgun`) problemet genom fyra kompromisslösa principer:

1. **Deklarera `import net_agent` (eller `import net_agent as alias`) överst i filen**: varje lib definierar sin `module :: net agent`-namnrymd och i `--strict`-läge anropas flerordsfunktioner alltid med naturliga mellanslag.
2. **Kedja dina datapipelines från vänster till höger med `->`**: skriv `indata steg ett -> steg två -> resultat`, använd `(+ _ _ +)`-sekvensmasker för att packa upp tupler och utelämna `_ =` vid sekventiella satser (eller kasta med `-> ()`).
3. **Svansrekursion med TCO (*Tail-Call Optimization*)**: alla interna genomlöpningar i `net_agent` kompileras till inbyggda hårdvaruloopar med $O(1)$ stackutrymme.
4. **Deterministiskt minne (`RMM1` / `RMM2`)**: varje mellanliggande struktur frigörs i exakt det ögonblick dess sista läsning avslutas, helt utan *Garbage Collector*.

---

## 32.2. Inbyggda artefakter, import och komplett API-katalog för `net_agent`

I `ridgun-libs` är **`net_agent`** en förstklassig **lib** placerad i `src/main/ridgun/lib/net_agent.ridgun` (domän `NETAGENT`). När du bygger med `stable bundle` paketeras den i ett inbyggt format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/net_agent.ridgunlib` | Portabel distribution och direkt import med `import net_agent` |

> Varje lib deklarerar sin egen namnrymd med `module :: net agent`: skriv bara `import net_agent` (eller `import net_agent as alias`) överst och anropa dess funktioner med naturliga mellanslag (`min funktion x`) och `->`-pipelines (`x min funktion -> resultat`).

### 32.2.1. Översikt över funktionella familjer i `net_agent`

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `ReactorConfig / reactor defaults / reactor with ...` | Gränserna för en reactor (anslutningar, accepteringar per varv, indata, utdata, första meddelandet, tid utan aktivitet) och deras standardvärden |
| `reactor start / reactor turn / reactor stop` | Startar en reactor på en lyssnande socket, kör ett varv (en väntan på allt, sedan acceptera, läsa och skicka) och stoppar den |
| `reactor arrived / reactor ready / reactor left` | Vad det senaste varvet lämnade: anslutningarna som kom, de med indata som inte har tagits och de som stängdes |
| `reactor input / reactor take / reactor send / reactor close after send / reactor peer` | En anslutning: dess indata, att ta de meddelanden som hittats, att köa utdata, att stänga efter sändning och motpartens adress |
| `reactor state / reactor set state` | Tillståndet som programmet håller för varje anslutning |
| `ConnStep / reactor each` | Det enkla fallet: en funktion som anropas för varje anslutning med indata och som svarar med nästa tillstånd, de byte som togs, utdata och om anslutningen ska stängas |
| `ReactorStats / reactor stats` | Anslutningar som är öppna, accepterade, nekade för att tabellen var full och stängda för att de gick över en gräns |

### 32.2.2. Komplett katalog över typer och signaturer i `src/main/ridgun/lib/net_agent.ridgun`

Nedan följer hela förteckningen över algebraiska datatyper (`type`), mixfix-operatorer (`op ::`) och funktionssignaturer (`fn ::`) som definieras i `src/main/ridgun/lib/net_agent.ridgun` (`5` typer, `0` operatorer och `70` funktioner):

**Algebraiska datatyper och poster (`type`) i `net_agent`:**

```ridgun
type ReactorConfig = max_conn_count: Int, max_accept_count: Int, input_limit_bytes: Int, output_limit_bytes: Int, first_message_limit_ms: Int, idle_limit_ms: Int
type ReactorStats = open_count: Int, accepted_count: Int, refused_count: Int, dropped_count: Int
type ReactorConn S = cn_id: Int, cn_fd: Int, cn_peer: String, cn_in: String, cn_out: String, cn_closing: Bool, cn_since: Int, cn_active: Int, cn_first: Bool, cn_done: Bool, cn_state: [S]
type Reactor S = rx_fd: Int, rx_cfg: ReactorConfig, rx_conns: [(ReactorConn S)], rx_next: Int, rx_arrived: [Int], rx_left: [Int], rx_accepted: Int, rx_refused: Int, rx_dropped: Int
type ConnStep S = ConnStep S Int String Bool
```

| # | Funktion / Signatur (`fn ::`) | Returtyp |
|---|---|---|
| `1` | `fn :: rx at least Int Int` | `Int` |
| `2` | `fn :: rx at most Int Int` | `Int` |
| `3` | `fn :: reactor defaults` | `ReactorConfig` |
| `4` | `fn :: reactor with max conns ReactorConfig Int` | `ReactorConfig` |
| `5` | `fn :: reactor with max accepts ReactorConfig Int` | `ReactorConfig` |
| `6` | `fn :: reactor with input limit ReactorConfig Int` | `ReactorConfig` |
| `7` | `fn :: reactor with output limit ReactorConfig Int` | `ReactorConfig` |
| `8` | `fn :: reactor with first message limit ReactorConfig Int` | `ReactorConfig` |
| `9` | `fn :: reactor with idle limit ReactorConfig Int` | `ReactorConfig` |
| `10` | `fn :: rx has [Int] Int` | `Bool` |
| `11` | `fn :: rx count [(ReactorConn S)] Int` | `Int` |
| `12` | `fn :: rx first or [S] S` | `S` |
| `13` | `fn :: rx read fds [(ReactorConn S)]` | `[Int]` |
| `14` | `fn :: rx write fds [(ReactorConn S)]` | `[Int]` |
| `15` | `fn :: rx listen fds Int` | `[Int]` |
| `16` | `fn :: rx pick ready [Int] [Int]` | `[Int]` |
| `17` | `fn :: reactor start Int ReactorConfig` | `Reactor S` |
| `18` | `fn :: rx refuse (Reactor S) Int` | `Reactor S` |
| `19` | `fn :: rx admit (Reactor S) Int String Int` | `Reactor S` |
| `20` | `fn :: rx accept one (Reactor S) Int Int (Int Int String)` | `Reactor S` |
| `21` | `fn :: rx accept some (Reactor S) Int Int` | `Reactor S` |
| `22` | `fn :: rx accept all (Reactor S) WaitMany Int` | `Reactor S` |
| `23` | `fn :: rx read got (ReactorConn S) Int (Int String)` | `Int (ReactorConn S)` |
| `24` | `fn :: rx drain got (ReactorConn S) (Int String)` | `Int (ReactorConn S)` |
| `25` | `fn :: rx read step (ReactorConn S) WaitMany Int` | `Int (ReactorConn S)` |
| `26` | `fn :: rx write got (ReactorConn S) Int (Int Int)` | `Int (ReactorConn S)` |
| `27` | `fn :: rx write step (Int (ReactorConn S)) WaitMany Int` | `Int (ReactorConn S)` |
| `28` | `fn :: rx over Int Int` | `Bool` |
| `29` | `fn :: rx linger ms` | `Int` |
| `30` | `fn :: rx shut sending (ReactorConn S) Int Int` | `Int (ReactorConn S)` |
| `31` | `fn :: rx after io ReactorConfig (Int (ReactorConn S)) Int` | `Int (ReactorConn S)` |
| `32` | `fn :: rx serve one ReactorConfig (ReactorConn S) WaitMany Int` | `Int (ReactorConn S)` |
| `33` | `fn :: rx serve each ReactorConfig [(ReactorConn S)] WaitMany Int` | `[Int (ReactorConn S)]` |
| `34` | `fn :: rx kept [Int (ReactorConn S)]` | `[(ReactorConn S)]` |
| `35` | `fn :: rx gone [Int (ReactorConn S)]` | `[Int]` |
| `36` | `fn :: rx gone closed (ReactorConn S) Int [Int (ReactorConn S)]` | `[Int]` |
| `37` | `fn :: rx limit count [Int (ReactorConn S)] Int` | `Int` |
| `38` | `fn :: rx serve done (Reactor S) [Int (ReactorConn S)]` | `Reactor S` |
| `39` | `fn :: reactor turn (Reactor S) [Int] Int` | `(Reactor S) [Int]` |
| `40` | `fn :: reactor arrived (Reactor S)` | `[Int]` |
| `41` | `fn :: reactor left (Reactor S)` | `[Int]` |
| `42` | `fn :: rx ready ids [(ReactorConn S)]` | `[Int]` |
| `43` | `fn :: reactor ready (Reactor S)` | `[Int]` |
| `44` | `fn :: rx input of [(ReactorConn S)] Int` | `String` |
| `45` | `fn :: reactor input (Reactor S) Int` | `String` |
| `46` | `fn :: rx peer of [(ReactorConn S)] Int` | `String` |
| `47` | `fn :: reactor peer (Reactor S) Int` | `String` |
| `48` | `fn :: rx taken (ReactorConn S) Int` | `ReactorConn S` |
| `49` | `fn :: rx take in [(ReactorConn S)] Int Int` | `[(ReactorConn S)]` |
| `50` | `fn :: reactor take (Reactor S) Int Int` | `Reactor S` |
| `51` | `fn :: rx send in [(ReactorConn S)] Int String` | `[(ReactorConn S)]` |
| `52` | `fn :: reactor send (Reactor S) Int String` | `Reactor S` |
| `53` | `fn :: rx closing in [(ReactorConn S)] Int` | `[(ReactorConn S)]` |
| `54` | `fn :: reactor close after send (Reactor S) Int` | `Reactor S` |
| `55` | `fn :: rx state of [(ReactorConn S)] Int S` | `S` |
| `56` | `fn :: reactor state (Reactor S) Int S` | `S` |
| `57` | `fn :: rx set state in [(ReactorConn S)] Int S` | `[(ReactorConn S)]` |
| `58` | `fn :: reactor set state (Reactor S) Int S` | `Reactor S` |
| `59` | `fn :: rx stepped (ReactorConn S) (ConnStep S)` | `ReactorConn S` |
| `60` | `fn :: rx each conn [(ReactorConn S)] S (S String` | `ConnStep S) => [(ReactorConn S)]` |
| `61` | `fn :: reactor each (Reactor S) S (S String` | `ConnStep S) => Reactor S` |
| `62` | `fn :: reactor stats (Reactor S)` | `ReactorStats` |
| `63` | `fn :: rx all closing [(ReactorConn S)]` | `[(ReactorConn S)]` |
| `64` | `fn :: rx close fds [(ReactorConn S)] Int` | `Int` |
| `65` | `fn :: rx stop listening (Reactor S)` | `Reactor S` |
| `66` | `fn :: rx stopped listening (Reactor S) Int` | `Reactor S` |
| `67` | `fn :: rx turn only ((Reactor S) [Int])` | `Reactor S` |
| `68` | `fn :: rx stop end (Reactor S)` | `ReactorStats` |
| `69` | `fn :: rx stop flush (Reactor S) Int` | `ReactorStats` |
| `70` | `fn :: reactor stop (Reactor S) Int` | `ReactorStats` |

---

## 32.3. Djupdykning i `net_agent`: Steg-för-steg-exempel för varje funktion

Det räcker inte med en signaturtabell: låt oss utforska **varje funktionalitet** i lib:en `net_agent` genom progressiva, körbara Ridgun-exempel. Vi börjar med två tabellbaserade vardagsrecept och går därefter igenom alla funktionella scenarier, transformationer och gränsfall som verifieras i `src/test/ridgun/test net_agent.ridgun`.

### 32.3.1. Exempel 1: Huvudflöde i tabellform med `net_agent`

Lägg märke till hur `=`-tecknen och transformationsstegen med `net_agent` linjeras som en ren tabell utan onödiga muterbara variabler eller dolda sidoeffekter:

```ridgun
import socket
import net_agent

fn :: fin de linea String Int => Int
      fin de linea s      i   =
        | i >= (str len s)        = 0 - 1
        | (str char at s i) == 10 = i
        | otherwise               = fin de linea s (i + 1)

-- El estado de cada conexión es cuántas líneas ha enviado.
fn :: responder Int String => ConnStep Int
      responder n   entrada =  linea vista n entrada (fin de linea entrada 0)

fn :: linea vista Int String  Int => ConnStep Int
      linea vista n   entrada fin =
        | fin < 0   = ConnStep n 0 "" False
        | otherwise = ConnStep (n + 1) (fin + 1) ("eco " + (str slice entrada 0 fin) + "\n") False

fn :: primero ((Reactor Int) [Int]) => Reactor Int
      primero (r, _)                =  r

-- Cada vuelta espera como mucho 100 ms a que pase algo, y después responde a quien tenga una línea completa.
fn :: servir (Reactor Int) Int     => ReactorStats
      servir r             vueltas =
        | vueltas <= 0 = reactor stop r 1000
        | otherwise    = servir (reactor each (primero (reactor turn r [] 100)) 0 (responder)) (vueltas - 1)

fn :: main => ()
      main =
        r = reactor start (sock fd (sys tcp listen "127.0.0.1" 0 64)) (reactor defaults)
        echo (accepted_count (servir r 10))
```

### 32.3.2. Exempel 2: Säker komposition och hantering av gränsfall

Varje funktion i lib:en `net_agent` är utformad för att kombineras sömlöst med booleska vakter `|` och med övriga 38 libs i `ridgun-libs`:

```ridgun
import socket
import net_agent

-- Límites estrictos: 100 conexiones, 4 KB de entrada y 1 MB de salida por conexión,
-- 5 s para el primer mensaje y 60 s de inactividad.
fn :: limites => ReactorConfig
      limites =
        c1 = reactor with max conns (reactor defaults) 100
        c2 = reactor with input limit c1 4096
        c3 = reactor with output limit c2 1048576
        c4 = reactor with first message limit c3 5000
        reactor with idle limit c4 60000

-- A cada conexión nueva se le encola un saludo y se marca para cerrar cuando se haya enviado.
fn :: saludar (Reactor Int) [Int]      => Reactor Int
      saludar r             []         =  r
      saludar r             (id:resto) =  saludar (reactor close after send (reactor send r id ("hola " + (reactor peer r id) + "\n")) id) resto

fn :: tras la vuelta ((Reactor Int) [Int]) => Reactor Int
      tras la vuelta (r, _)                =  saludar r (reactor arrived r)

fn :: una vuelta (Reactor Int) => Reactor Int
      una vuelta r             =  tras la vuelta (reactor turn r [] 100)

fn :: main => ()
      main =
        r0 = reactor start (sock fd (sys tcp listen "127.0.0.1" 0 64)) (limites)
        r1 = una vuelta (una vuelta r0)
        s  = reactor stats r1
        echo "abiertas {open_count s}, rechazadas {refused_count s}, cerradas por un límite {dropped_count s}"
        echo (accepted_count (reactor stop r1 500))
```

### 32.3.3. Exempel 3: Acceptera upp till en gräns per varv, neka när tabellen är full och id:n som aldrig återanvänds



```ridgun
fn :: test reactor accepts and refuses => ()
      test reactor accepts and refuses =
        d = reactor defaults
        max_conn_count d -> assert int equals 1024 "defaults: 1 024 connections"
        max_accept_count d -> assert int equals 64 "64 accepted in a turn"
        input_limit_bytes d -> assert int equals 67108864 "64 MB of input"
        output_limit_bytes d -> assert int equals 67108864 "64 MB of output"
        first_message_limit_ms d -> assert int equals 0 "no limit for the first message"
        idle_limit_ms d -> assert int equals 0 "no idle limit"
        max_conn_count (reactor with max conns d 0) -> assert int equals 1 "a table holds at least one connection"

        lfd = na listen
        r0  = na start lfd (reactor with max accepts (reactor with max conns d 2) 2)
        e0  = na turn r0 20
        na count (reactor arrived e0) 0 -> assert int equals 0 "nobody connected: nothing arrived"
        open_count (reactor stats e0) -> assert int equals 0 "and the table is empty"

        c1 = na client lfd
        c2 = na client lfd
        c3 = na client lfd
        r1 = na turn r0 500
        na same (reactor arrived r1) [1, 2] -> assert true "AC1: three are pending and a turn accepts two, with ids from 1"
        reactor peer r1 1 -> assert str eq "127.0.0.1" "AC1: the address of the peer"
        reactor peer r1 99 -> assert str eq "" "an id that is not in the table has no peer"
        open_count (reactor stats r1) -> assert int equals 2 "AC12: two open"
        accepted_count (reactor stats r1) -> assert int equals 2 "AC12: two accepted"
        r2 = na turn r1 500
        na count (reactor arrived r2) 0 -> assert int equals 0 "AC2: the table is full, the third does not enter"
        refused_count (reactor stats r2) -> assert int equals 1 "AC2: and it is counted as refused"
        open_count (reactor stats r2) -> assert int equals 2 "AC2: the two in the table are still there"
        na recv rc (sys recv c3 16 500) -> assert int equals (0 - 1) "AC2: the refused client sees its connection closed"

        posix close c1
        r3 = na turn r2 500
        na same (reactor left r3) [1] -> assert true "AC3: a connection closed by its peer leaves the table"
        open_count (reactor stats r3) -> assert int equals 1 "one open"
        c4 = na client lfd
        r4 = na turn r3 500
        na same (reactor arrived r4) [3] -> assert true "AC1: an id is never given again: the next one is 3"
        na count (reactor left r4) 0 -> assert int equals 0 "what left is of the last turn only"
        accepted_count (reactor stats r4) -> assert int equals 3 "three accepted in all"
        dropped_count (reactor stats r4) -> assert int equals 0 "none closed for a limit"
        st = reactor stop r4 200
        open_count st -> assert int equals 0 "after the stop nothing is open"
        posix close c2
        posix close c3
        posix close c4 -> ()
```

### 32.3.4. Exempel 4: Ett meddelande som kommer i delar, tillståndet för varje anslutning och ett radprotokoll med `reactor each`



```ridgun
fn :: test reactor input messages and state => ()
      test reactor input messages and state =
        lfd = na listen
        r0  = na start lfd (reactor defaults)
        c1  = na client lfd
        r1  = na turn r0 500
        na same (reactor arrived r1) [1] -> assert true "one connection"
        na count (reactor ready r1) 0 -> assert int equals 0 "it has sent nothing: not ready"
        sock rc (sys send c1 "hel" 500) -> assert int equals 0 "the client sends a part"
        r2  = na turn r1 500
        na same (reactor ready r2) [1] -> assert true "AC3: its bytes are in the input"
        reactor input r2 1 -> assert str eq "hel" "AC3: the input"
        r3  = reactor take r2 1 0
        reactor input r3 1 -> assert str eq "hel" "AC4: nothing taken, the bytes stay"
        sock rc (sys send c1 "lo\nwor" 500) -> assert int equals 0 "the rest of the message and the start of another"
        r4  = na turn r3 500
        reactor input r4 1 -> assert str eq "hello\nwor" "AC4: a message that came in two reads is whole, once"
        r5  = reactor take r4 1 6
        reactor input r5 1 -> assert str eq "wor" "AC4: the message is taken and the rest stays"
        r6  = na turn r5 30
        reactor input r6 1 -> assert str eq "wor" "AC4: and it is still there a turn later"
        sock rc (sys send c1 "ld\n" 500) -> assert int equals 0 "the end of the second message"
        r7  = na turn r6 500
        reactor input r7 1 -> assert str eq "world\n" "AC4: offered again with what arrived later"
        r8  = reactor take r7 1 100
        reactor input r8 1 -> assert str eq "" "taking more than there is takes it all"
        reactor input r8 77 -> assert str eq "" "an id that is not in the table has no input"

        -- AC10: the state of each connection
        reactor state r8 1 5 -> assert int equals 5 "AC10: no state left yet: the default"
        r9  = reactor set state r8 1 41
        reactor state r9 1 5 -> assert int equals 41 "AC10: the state that was left"
        c2  = na client lfd
        r10 = na turn r9 500
        reactor state r10 2 5 -> assert int equals 5 "AC10: another connection has its own"
        reactor state r10 1 5 -> assert int equals 41 "AC10: and the first one keeps its state"
        open_count (reactor stats (reactor set state r10 99 1)) -> assert int equals 2 "an operation on an id that is not there changes nothing"

        -- reactor each: a protocol of lines
        l0  = na start (na listen) (reactor defaults)
        d1  = na client (rx_fd l0)
        d2  = na client (rx_fd l0)
        l1  = na turn l0 500
        sock rc (sys send d1 "a\nb\npart" 500) -> assert int equals 0 "two lines and a part"
        sock rc (sys send d2 "x\n" 500) -> assert int equals 0 "the other client, one line"
        l2  = reactor each (na turns l1 2 100) 0 (na line step)
        reactor input l2 1 -> assert str eq "b\npart" "each: one call for each connection, it took one line"
        reactor state l2 1 0 -> assert int equals 1 "each: the state it left"
        l3  = reactor each l2 0 (na line step)
        reactor input l3 1 -> assert str eq "part" "each: the second line; the part stays"
        reactor state l3 1 0 -> assert int equals 2 "each: its state after two lines"
        reactor state l3 2 0 -> assert int equals 1 "each: the other connection has its own count"
        l4  = reactor each l3 0 (na line step)
        reactor state l4 1 0 -> assert int equals 2 "each: no whole line, nothing changes"
        p1  = na pump l4 d1 8 40 ""
        na pumped text p1 -> assert str eq "1:a\n2:b\n" "AC5: the answers leave in the order they were queued"
        p2  = na pump (na pumped r p1) d2 4 40 ""
        na pumped text p2 -> assert str eq "1:x\n" "each connection gets its own answer"
        sock rc (sys send d1 "ial\nquit\n" 500) -> assert int equals 0 "the rest of the line, and quit"
        l5  = reactor each (na turns (na pumped r p2) 2 100) 0 (na line step)
        l6  = reactor each l5 0 (na line step)
        p3  = na pump l6 d1 11 40 ""
        na pumped text p3 -> assert str eq "3:partial\nbye\n" "the line that came in two parts is answered once, whole"
        l7  = na turns (na pumped r p3) 3 50
        na recv rc (sys recv d1 16 500) -> assert int equals (0 - 1) "AC7: after the answer to quit the client sees the end"
        open_count (reactor stats l7) -> assert int equals 2 "the reactor waits for the client to close its side"
        posix close d1
        l8  = na turns l7 3 50
        open_count (reactor stats l8) -> assert int equals 1 "AC7: and then the connection leaves the table"
        dropped_count (reactor stats l8) -> assert int equals 0 "not counted as closed for a limit"
        reactor stop l8 100
        reactor stop r10 100
        posix close c1
        posix close c2
        posix close d2 -> ()
```

### 32.3.5. Exempel 5: Utdata i ordning, ett stort svar över flera varv och motparten som inte läser



```ridgun
fn :: test reactor output and the peer that does not read => ()
      test reactor output and the peer that does not read =
        lfd  = na listen
        r0   = na start lfd (reactor with output limit (reactor defaults) 3000000)
        slow = na client lfd
        fast = na client lfd
        r1   = na turn r0 500
        na same (reactor arrived r1) [1, 2] -> assert true "two connections"
        big  = na text 2000000
        r2   = reactor send (reactor send r1 2 "one") 2 "two"
        p0   = na pump r2 fast 6 40 ""
        na pumped text p0 -> assert str eq "onetwo" "AC5: what was queued leaves in its order"

        -- AC5: a reply larger than the socket takes at once goes out over several turns, whole
        r3   = reactor send (na pumped r p0) 2 big
        p1   = na pump r3 fast 2000000 4000 ""
        str len (na pumped text p1) -> assert int equals 2000000 "AC5: two million bytes arrive"
        (na pumped text p1) == big -> assert true "AC5: and they are the bytes that were queued"

        -- AC6: the peer that does not read does not delay the others
        r4   = reactor send (na pumped r p1) 1 big
        t0   = sys monotonic ms
        r5   = na turns r4 5 20
        (sys monotonic ms) - t0 < 1500 -> assert true "AC6: five turns with a peer that does not read do not wait for it"
        open_count (reactor stats r5) -> assert int equals 2 "under the limit it stays, with its output queued"
        r6   = reactor send r5 2 "still here"
        p2   = na pump r6 fast 10 40 ""
        na pumped text p2 -> assert str eq "still here" "AC6: the other connection is served meanwhile"
        r7   = reactor send (na pumped r p2) 1 (big + big + big + big + big + big)
        r8   = na turns r7 3 20
        na same (reactor left r8) [] -> assert true "left is of the last turn"
        dropped_count (reactor stats r8) -> assert int equals 1 "AC6: past the output limit the connection is closed and counted"
        open_count (reactor stats r8) -> assert int equals 1 "AC6: and only that one"
        r9   = reactor send r8 2 "after"
        p3   = na pump r9 fast 5 40 ""
        na pumped text p3 -> assert str eq "after" "the other connection goes on"

        -- AC7: marked to close: its output is sent first, and nothing more is read from it
        c3   = na client lfd
        r10  = na turn (na pumped r p3) 500
        na same (reactor arrived r10) [3] -> assert true "a third connection"
        r11  = reactor close after send (reactor send r10 3 (na text 1500000)) 3
        sock rc (sys send c3 "ignored" 500) -> assert int equals 0 "the client sends after it was marked"
        r12  = na turns r11 3 20
        reactor input r12 3 -> assert str eq "" "AC7: nothing is read from a connection marked to close"
        p4   = na pump r12 c3 1500000 4000 ""
        str len (na pumped text p4) -> assert int equals 1500000 "AC7: its queued output is sent whole"
        r13a = na turns (na pumped r p4) 3 50
        na recv rc (sys recv c3 16 500) -> assert int equals (0 - 1) "AC7: and then the client sees the end, with nothing lost"
        posix close c3
        r13  = na turns r13a 3 50
        open_count (reactor stats r13) -> assert int equals 1 "it left the table"
        dropped_count (reactor stats r13) -> assert int equals 1 "and was not counted as closed for a limit"

        -- a client that never closes its side: the reactor closes it after waiting one second
        c5   = na client lfd
        r14  = na turn r13 500
        r15  = reactor close after send (reactor send r14 4 "end") 4
        r16  = na turns r15 3 50
        na read c5 500 -> assert str eq "end" "the last output arrives"
        open_count (reactor stats r16) -> assert int equals 2 "the client has not closed: the connection waits"
        r17  = na turns r16 14 100
        open_count (reactor stats r17) -> assert int equals 1 "AC7: after one second the reactor closes it anyway"

        -- AC3: the input limit
        l2   = na start (na listen) (reactor with input limit (reactor defaults) 1000)
        c4   = na client (rx_fd l2)
        l3   = na turn l2 500
        sock rc (sys send c4 (na text 5000) 500) -> assert int equals 0 "five thousand bytes into a limit of one thousand"
        l4   = na turns l3 2 100
        dropped_count (reactor stats l4) -> assert int equals 1 "AC3: past the input limit the connection is closed and counted"
        open_count (reactor stats l4) -> assert int equals 0 "and leaves the table"
        reactor stop l4 100
        reactor stop r17 100
        posix close slow
        posix close fast
        posix close c4
        posix close c5 -> ()
```

### 32.3.6. Exempel 6: Tiden för det första meddelandet och tiden utan aktivitet



```ridgun
fn :: test reactor time limits => ()
      test reactor time limits =
        lfd = na listen
        r0  = na start lfd (reactor with first message limit (reactor defaults) 150)
        c1  = na client lfd
        c2  = na client lfd
        r1  = na turn r0 500
        sock rc (sys send c2 "msg\n" 500) -> assert int equals 0 "the second sends its first message"
        r2  = reactor take (na turn r1 500) 2 4
        r3  = na turns r2 6 60
        dropped_count (reactor stats r3) -> assert int equals 1 "AC8: the one that sent no whole message in 150 ms is closed"
        open_count (reactor stats r3) -> assert int equals 1 "AC8: the one whose message was taken stays"
        na recv rc (sys recv c1 16 500) -> assert int equals (0 - 1) "the silent client sees the close"
        reactor stop r3 100

        l0  = na start (na listen) (reactor with idle limit (reactor defaults) 150)
        d1  = na client (rx_fd l0)
        l1  = na turn l0 500
        sock rc (sys send d1 "hi" 500) -> assert int equals 0 "it sends"
        l2  = na turns l1 2 40
        open_count (reactor stats l2) -> assert int equals 1 "AC8: active within the idle limit: it stays"
        l3  = na turns l2 6 60
        dropped_count (reactor stats l3) -> assert int equals 1 "AC8: silent for longer than the idle limit: closed"
        open_count (reactor stats l3) -> assert int equals 0 "and gone from the table"
        reactor stop l3 100
        posix close c1
        posix close c2
        posix close d1 -> ()
```

### 32.3.7. Exempel 7: En enda väntan på allt: anslutningar, en pipe från anroparen och en arbetarpool



```ridgun
fn :: test reactor waits on everything at once => ()
      test reactor waits on everything at once =
        lfd = na listen
        r0  = na start lfd (reactor defaults)
        pp  = posix pipe
        pr  = tuple3 r pp
        pw  = tuple3 w pp

        -- AC9: nothing happens: the turn sleeps for its limit and answers nothing
        t0  = sys monotonic ms
        a0  = reactor turn r0 [pr] 120
        t1  = sys monotonic ms
        na count (na second a0) 0 -> assert int equals 0 "AC9: nothing ready"
        (t1 - t0) >= 100 -> assert true "AC9: the turn slept for its limit, it did not spin"
        (t1 - t0) < 1500 -> assert true "and not much longer"

        -- a descriptor of the caller wakes it
        posix write pw "x" -> assert int equals 1 "a byte in the pipe"
        t2  = sys monotonic ms
        a1  = reactor turn (na first a0) [pr] 5000
        na same (na second a1) [pr] -> assert true "AC9: the descriptor of the caller is named as ready"
        (sys monotonic ms) - t2 < 1000 -> assert true "AC9: and the turn returned at once, not after 5 s"

        -- a connection wakes it
        c1  = na client lfd
        t3  = sys monotonic ms
        a2  = reactor turn (na first a1) [] 5000
        na same (reactor arrived (na first a2)) [1] -> assert true "AC9: a new connection wakes the turn"
        (sys monotonic ms) - t3 < 1000 -> assert true "at once"
        sock rc (sys send c1 "data" 500) -> assert int equals 0 "the client sends"
        t4  = sys monotonic ms
        a3  = reactor turn (na first a2) [] 5000
        reactor input (na first a3) 1 -> assert str eq "data" "AC9: bytes on a connection wake the turn"
        (sys monotonic ms) - t4 < 1000 -> assert true "at once"

        -- the descriptor of a worker pool
        p0  = pool start 1 (na slow double) 0
        k, p1 = pool submit p0 21 ""
        a4  = reactor turn (na first a3) [pool done fd p1] 5000
        na same (na second a4) [pool done fd p1] -> assert true "AC9: the turn waits on the descriptor of a worker pool and names it when a job ends"
        done, p2 = pool drain p1 1000
        reactor stop (na first a4) 100
        posix close pr
        posix close pw
        posix close c1 -> ()
```

### 32.3.8. Exempel 8: Stoppet: det som står i kö skickas och allt stängs



```ridgun
fn :: test reactor stop => ()
      test reactor stop =
        lfd  = na listen
        port = sys local port lfd
        r0   = na start lfd (reactor defaults)
        c1   = na client lfd
        c2   = na client lfd
        r1   = na turn r0 500
        r2   = reactor send (reactor send r1 1 "last words one") 2 "last words two"
        st   = reactor stop r2 1000
        open_count st -> assert int equals 0 "AC11: after the stop nothing is open"
        accepted_count st -> assert int equals 2 "AC12: the counters at the end"
        na read c1 500 -> assert str eq "last words one" "AC11: the queued output was sent before closing"
        na read c2 500 -> assert str eq "last words two" "AC11: to each connection"
        na recv rc (sys recv c1 16 500) -> assert int equals (0 - 1) "AC11: and the connections are closed"
        sock rc (sys tcp connect "127.0.0.1" port 300) != 0 -> assert true "AC11: the listening socket is closed: nobody can connect"

        -- a peer that does not read does not hold the stop longer than its time
        l0   = na start (na listen) (reactor defaults)
        d1   = na client (rx_fd l0)
        l1   = reactor send (na turn l0 500) 1 (na text 3000000)
        t0   = sys monotonic ms
        s2   = reactor stop l1 300
        (sys monotonic ms) - t0 < 2000 -> assert true "AC11: the stop ends at its time limit"
        open_count s2 -> assert int equals 0 "and everything is closed"
        posix close c1
        posix close c2
        posix close d1 -> ()
```

---

## 32.4. Under huven: hur `net_agent` är byggd i ren Ridgun (`src/main/ridgun/lib/net_agent.ridgun`)

En av de största fördelarna med `ridgun-libs` är att **det inte finns några svarta lådor i C**. Du kan öppna `src/main/ridgun/lib/net_agent.ridgun` och läsa exakt hur varje operation är implementerad med mönstermatchning, `|` / `|.`-vaktträd och svansrekursion (TCO). Låt oss titta på nyckeldelarna i den faktiska implementationen:

### 32.4.1. Intern implementation: Accepting (AC1, AC2)

Se hur `net_agent.ridgun` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
module :: net_agent

-- The table is full: the new connection is closed at once and counted.
fn :: rx refuse (Reactor S) Int => Reactor S
      rx refuse r           fd  =
        closed = posix close fd
        r with rx_refused = (rx_refused r) + 1

fn :: rx admit (Reactor S) Int String Int => Reactor S
      rx admit r           fd  ip     now =
        r with rx_conns = (rx_conns r) :: [ReactorConn (rx_next r) fd ip "" "" False now now False False []], rx_next = (rx_next r) + 1, rx_arrived = (rx_arrived r) :: [rx_next r], rx_accepted = (rx_accepted r) + 1

fn :: rx accept one (Reactor S) Int Int (Int Int String) => Reactor S
      rx accept one r           now left (rc, fd, ip)    =
        | rc != 0                                                  = r
        | (rx count (rx_conns r) 0) >= (max_conn_count (rx_cfg r)) = rx accept some (rx refuse r fd) now (left - 1)
        | otherwise                                                = rx accept some (rx admit r fd ip now) now (left - 1)

-- Accepts those that are pending, without waiting, at most `left` of them.
fn :: rx accept some (Reactor S) Int Int => Reactor S
      rx accept some r           now left =
        | left <= 0 = r
        | otherwise = rx accept one r now left (sys accept (rx_fd r) 0)

fn :: rx accept all (Reactor S) WaitMany Int => Reactor S
      rx accept all r           w        now =
        | (rx_fd r) < 0                      = r
        | not (rx has (wm_read w) (rx_fd r)) = r
        | otherwise                          = rx accept some r now (max_accept_count (rx_cfg r))
```

### 32.4.2. Intern implementation: Reading, sending and the limits (AC3, AC5, AC6, AC7, AC8)

Se hur `net_agent.ridgun` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
-- Each step answers a kind with the connection: 0 it stays, 1 it leaves (its peer closed, it failed, or it
-- was marked to close and its output is sent), 2 it leaves for passing a limit.

fn :: rx read got (ReactorConn S) Int (Int String) => Int (ReactorConn S)
      rx read got c               now (rc, data)   =
        | rc == 0       = (0, c with cn_in = (cn_in c) + data, cn_active = now)
        | rc == (0 - 2) = (0, c)
        | otherwise     = (1, c)

-- A connection that only waits for its peer to close: what arrives is thrown away; the end of the peer ends it.
fn :: rx drain got (ReactorConn S) (Int String) => Int (ReactorConn S)
      rx drain got c               (rc, data)   =
        | rc == 0       = (0, c)
        | rc == (0 - 2) = (0, c)
        | otherwise     = (1, c)

-- What has arrived is added to the input, without waiting. A closing connection is not read.
fn :: rx read step (ReactorConn S) WaitMany Int => Int (ReactorConn S)
      rx read step c               w        now =
        | not (rx has (wm_read w) (cn_fd c)) = (0, c)
        | cn_done c                          = rx drain got c (sys recv (cn_fd c) 65536 0)
        | cn_closing c                       = (0, c)
        | otherwise                          = rx read got c now (sys recv (cn_fd c) 65536 0)

fn :: rx write got (ReactorConn S) Int (Int Int) => Int (ReactorConn S)
      rx write got c               now (rc, sent) =
        | rc == 0                    = (0, c with cn_out = "", cn_active = now)
        | rc == (0 - 2) and sent > 0 = (0, c with cn_out = (str slice (cn_out c) sent (str len (cn_out c))), cn_active = now)
        | rc == (0 - 2)              = (0, c)
        | otherwise                  = (1, c)

-- The peer is sent what it takes now; the rest stays queued, in its order.
fn :: rx write step (Int (ReactorConn S)) WaitMany Int => Int (ReactorConn S)
      rx write step (kind, c)             w        now =
        | kind != 0                           = (kind, c)
        | (str len (cn_out c)) == 0           = (0, c)
        | not (rx has (wm_write w) (cn_fd c)) = (0, c)
        | otherwise                           = rx write got c now (sys send (cn_fd c) (cn_out c) 0)

fn :: rx over Int   Int   => Bool
      rx over limit spent =  (limit > 0) and (spent > limit)

-- How long a connection whose output is all sent waits for its peer to close before it is closed anyway.
fn :: rx linger ms => Int
      rx linger ms =  1000

-- The output of a closing connection is all sent: its sending side is shut, so the peer sees the end after the
-- last byte. The connection is not closed yet: closing a socket that still holds bytes the peer sent makes the
-- kernel cut the connection, and the peer can lose output it had not read.
fn :: rx shut sending (ReactorConn S) Int Int => Int (ReactorConn S)
      rx shut sending c               now _   =  (0, c with cn_done = True, cn_active = now)

fn :: rx after io ReactorConfig (Int (ReactorConn S)) Int => Int (ReactorConn S)
      rx after io cfg           (kind, c)             now =
        | kind != 0                                                                        = (kind, c)
        | (cn_done c) and ((now - (cn_active c)) > (rx linger ms))                         = (1, c)
        | cn_done c                                                                        = (0, c)
        | (cn_closing c) and ((str len (cn_out c)) == 0)                                   = rx shut sending c now (sys shutdown write (cn_fd c))
        | (str len (cn_in c)) > (input_limit_bytes cfg)                                    = (2, c)
        | (str len (cn_out c)) > (output_limit_bytes cfg)                                  = (2, c)
        | (not (cn_first c)) and (rx over (first_message_limit_ms cfg) (now - (cn_since c))) = (2, c)
        | rx over (idle_limit_ms cfg) (now - (cn_active c))                                = (2, c)
        | otherwise                                                                        = (0, c)

fn :: rx serve one ReactorConfig (ReactorConn S) WaitMany Int => Int (ReactorConn S)
      rx serve one cfg           c               w        now =
        | rx has (wm_failed w) (cn_fd c) = (1, c)
        | otherwise                      = rx after io cfg (rx write step (rx read step c w now) w now) now

fn :: rx serve each ReactorConfig [(ReactorConn S)] WaitMany Int => [Int (ReactorConn S)]
      rx serve each cfg           []                w        now =  []
      rx serve each cfg           (c:rest)          w        now =  [rx serve one cfg c w now] :: (rx serve each cfg rest w now)

-- The connections that stay.
fn :: rx kept [Int (ReactorConn S)] => [(ReactorConn S)]
      rx kept []                    =  []
      rx kept ((kind, c):rest)      =
        | kind == 0 = [c] :: (rx kept rest)
        | otherwise = rx kept rest

-- The ids of the connections that leave; each one is closed here, once.
fn :: rx gone [Int (ReactorConn S)] => [Int]
      rx gone []                    =  []
      rx gone ((kind, c):rest)      =
        | kind == 0 = rx gone rest
        | otherwise = rx gone closed c (posix close (cn_fd c)) rest

fn :: rx gone closed (ReactorConn S) Int [Int (ReactorConn S)] => [Int]
      rx gone closed c               _   rest                  =  [cn_id c] :: (rx gone rest)

fn :: rx limit count [Int (ReactorConn S)] Int => Int
      rx limit count []                    n   =  n
      rx limit count ((kind, c):rest)      n   =
        | kind == 2 = rx limit count rest (n + 1)
        | otherwise = rx limit count rest n

fn :: rx serve done (Reactor S) [Int (ReactorConn S)] => Reactor S
      rx serve done r           served                =
        r with rx_conns = (rx kept served), rx_left = (rx gone served), rx_dropped = (rx_dropped r) + (rx limit count served 0)
```

### 32.4.3. Intern implementation: One turn (AC9)

Se hur `net_agent.ridgun` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
-- One turn of the loop. It waits at most `timeout_ms` for the listening socket, every connection and the
-- descriptors of the caller in `extra` (a signal descriptor, the descriptor of a worker pool): one wait on all
-- of them. Then it accepts, reads, sends and applies the limits, without waiting for any connection.
-- The answer is the reactor to use from now on and the descriptors of `extra` that are ready.
fn :: reactor turn (Reactor S) [Int] Int        => (Reactor S) [Int]
      reactor turn r           extra timeout_ms =
        w   = posix wait many ((rx listen fds (rx_fd r)) :: ((rx read fds (rx_conns r)) :: extra)) (rx write fds (rx_conns r)) timeout_ms
        now = sys monotonic ms
        r1  = rx accept all (r with rx_arrived = [], rx_left = []) w now
        r2  = rx serve done r1 (rx serve each (rx_cfg r1) (rx_conns r1) w now)
        (r2, rx pick ready extra (wm_read w))
```

### 32.4.4. Intern implementation: Stop (AC11)

Se hur `net_agent.ridgun` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
fn :: rx all closing [(ReactorConn S)] => [(ReactorConn S)]
      rx all closing []                =  []
      rx all closing (c:rest)          =  [c with cn_closing = True] :: (rx all closing rest)

fn :: rx close fds [(ReactorConn S)] Int => Int
      rx close fds []                n   =  n
      rx close fds (c:rest)          n   =  rx close fds rest (n + (rx at most (posix close (cn_fd c)) 0) + 1)

fn :: rx stop listening (Reactor S) => Reactor S
      rx stop listening r           =
        | (rx_fd r) < 0 = r
        | otherwise     = rx stopped listening r (posix close (rx_fd r))

fn :: rx stopped listening (Reactor S) Int => Reactor S
      rx stopped listening r           _   =  r with rx_fd = (0 - 1)

fn :: rx turn only ((Reactor S) [Int]) => Reactor S
      rx turn only (r, _)              =  r

fn :: rx stop end (Reactor S) => ReactorStats
      rx stop end r           =
        n = rx close fds (rx_conns r) 0
        ReactorStats 0 (rx_accepted r) (rx_refused r) (rx_dropped r)

-- Turns that only send, until nothing is queued or the time ends.
fn :: rx stop flush (Reactor S) Int      => ReactorStats
      rx stop flush r           deadline =
        | (rx count (rx_conns r) 0) == 0 = rx stop end r
        | (sys monotonic ms) >= deadline = rx stop end r
        | otherwise                      = rx stop flush (rx turn only (reactor turn r [] (rx at most (deadline - (sys monotonic ms)) 50))) deadline

-- Stops the reactor: no more connections are accepted, the queued output is sent for at most `timeout_ms`,
-- and every connection and the listening socket are closed. The answer is the counters at the end.
fn :: reactor stop (Reactor S) Int        => ReactorStats
      reactor stop r           timeout_ms =
        s = rx stop listening r
        rx stop flush (s with rx_conns = (rx all closing (rx_conns s))) ((sys monotonic ms) + (rx at least timeout_ms 0))
```

---

## 32.5. Algoritmiska garantier, `RMM1`/`RMM2`-minne och de 5 Gyllene Reglerna för `net_agent`

- **Algoritmisk garanti och säkerhet**: Ingen anslutning får en annan att vänta: den enda väntan i ett varv är en väntan på alla deskriptorer samtidigt. Tabellen, den indata och utdata som hålls för en anslutning, tiden för dess första meddelande och dess tid utan aktivitet är alla begränsade, och en anslutning som går över en gräns stängs och räknas. En anslutning som är märkt för stängning stängs ordnat, så att motparten inte förlorar någon utdata.
- **$O(1)$ stackkomplexitet med TCO**: Alla rekursiva loopar i `src/main/ridgun/lib/net_agent.ridgun` ligger i svansposition, så `ridgunc` kompilerar dem till inbyggda hopp utan stacktillväxt.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test net_agent.ridgun`.

### De 5 Gyllene Reglerna när du programmerar med `net_agent`

1. **Deklarera `import net_agent` överst i filen** och anropa dess funktioner med mellanslag, precis som de är deklarerade, så att koden läses som naturlig prosa.
2. **Linjera dina datapipelines med `=`**: kedja samman `net_agent`-anrop i namngivna mellansteg och låt `stable format` linjera kolumnerna.
3. **Utnyttja `net_agent`:s totala funktioner i dina `|`-vakter**: kontrollera returvärden eller packa upp ADT:er med mönstermatchning i stället för att anta att extern indata alltid är giltig.
4. **Undvik att kopiera stora strukturer när du bara läser ett fält**: kom ihåg att i `RMM2` medför inargument noll referensräkningskostnad (`+0` / `-0`).
5. **Kombinera `net_agent` med `test` (`import test`)**: lås alltid fast dina domäninvarianter med `assert equals` eller `assert true`.

---

I **Kapitel 33** går vi vidare och utforskar lib:en **`ai`** på djupet (Libben `ai` — AI-agenter, Tool Calling, SSE-streaming, Begränsad ReAct, Skyddsräcken, Mini-RAG och MCP).
