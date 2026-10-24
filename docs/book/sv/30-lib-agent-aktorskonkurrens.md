# Kapitel 30: Lib:en `agent` — Inbyggd Aktörskonkurrens (`agent`, `send`, `receive`), KV-lagring och Rate Limiter

## 1. Varför finns lib:en `agent`?

Låt oss vara ärliga: att dela muterbart minne mellan trådar med `Mutex`, `RwLock` och villkorsvariabler är en outsinlig fabrik av *deadlocks* och kapplöpningsvillkor.

Lib:en **`agent`** bygger vidare på Ridguns **inbyggda aktörsmodell** (`agent`, `send ... to`, `receive from`, `try receive from`, `stop`) och erbjuder isolerade brevlådor med Copy-on-Write-meddelanden, en konkurrent nyckel-värde-lagring (`KvStore`), en *token-bucket*-begränsare (`RateBucket`) samt övervakning (`AgentHealth`).

---

## 2. Paket, import och arkitektur helt utan `libc`

I `ridgun-libs` är **`agent`** en förstklassig **lib** placerad i `src/main/ridgun/lib/agent.rg` (domän `AGENT`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/agent.rglib` | Portabel distribution och direkt import med `import agent` |
| **Kompilerat arkiv** | `target/agent.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libagent.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import agent` överst och anropar funktionerna med mellanslag eller understreck.

---

## 3. Snabbreferens för `agent`-API:et

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `agent roundtrip / agent drain count` | Startar inbyggda aktörer (`agent`), utbyter meddelanden (`send ... to` / `receive from`) och kör `stop` |
| `kv store new / kv store apply` | Oföränderlig nyckel-värde-lagring för aktörer (`KvPut`, `KvGet`, `KvDelete`, `KvClear`) |
| `rate bucket new / rate bucket allow` | *Token-bucket*-begränsare som returnerar uppdaterad hink och `(allowed, remaining)` |
| `sup mark failed / sup should restart` | Övervakningsfunktioner som spårar omstartsbudget (`max_restarts`) |

---

## 4. Praktiska recept i tabellform

### Recept 1: Huvudflöde med `agent`

Lägg märke till hur `=`-tecknen och transformationsstegen linjeras som en ren tabell:

```ridgun
import agent

fn :: probar actor nativo () => (Int, Int)
      probar actor nativo =
        eco = agent roundtrip 42
        vac = agent drain count [10, 20, 30]
        (eco, vac)
```

### Recept 2: Säker komposition utan sidoeffekter

Varje funktion i lib:en `agent` kan kombineras fritt med övriga 32 libs i `ridgun-libs`:

```ridgun
import agent

fn :: aplicar limite peticion () => (Bool, Int)
      aplicar limite peticion =
        b0         = rate bucket new 10 2 1000
        (b1, res1) = rate bucket allow b0 1 1000
        rateresp allowed res1, rateobs remaining res1
```

---

## 5. Under huven: prestanda, RMM-minne och garantier

- **Algoritmisk garanti och säkerhet**: Noll delat muterbart minne mellan aktörer: varje meddelande överförs via värde / Copy-on-Write och `stop` frigör aktörens minnesregion deterministiskt.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test_agent.rg`.
