# Kapitel 32: Lib:en `net_agent` — Övervakare för Nätverksanslutningar och Icke-blockerande Händelsebrygga

## 1. Varför finns lib:en `net_agent`?

Låt oss vara ärliga: i en riktig server som **Solstice** är det enkelt att acceptera TCP-anslutningar; det svåra är att begränsa max antal samtidiga klienter, rensa bort inaktiva zombie-anslutningar (*idle timeout*) och koppla ihop `ppoll`-loopen med dina aktörer utan att läcka fildeskriptorer.

Lib:en **`net_agent`** sluter cirkeln i `ridgun-libs` genom att förena **`posix`**, **`socket`** och **`agent`**: den hanterar övervakade anslutningstabeller (`NetSupervisor`), upprätthåller gränser för samtidiga klienter (`max_conns`), rensar inaktiva anslutningar (`net evict idle`), översätter kärndeskriptor-polling till typade aktörshändelser (`NetEvReadyRead`, `NetEvReadyWrite`, `NetEvTimeout`, `NetEvError`) och erbjuder ett komplett övervakat TCP-ekosteg (`net tcp echo step`).

---

## 2. Paket, import och arkitektur helt utan `libc`

I `ridgun-libs` är **`net_agent`** en förstklassig **lib** placerad i `src/main/ridgun/lib/net_agent.rg` (domän `AGENT`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/net_agent.rglib` | Portabel distribution och direkt import med `import net_agent` |
| **Kompilerat arkiv** | `target/net_agent.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libnet_agent.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import net_agent` överst och anropar funktionerna med mellanslag eller understreck.

---

## 3. Snabbreferens för `net_agent`-API:et

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `net supervisor new : Int -> Int -> NetSupervisor` | Skapar en anslutningsövervakare med `max_conns` och `idle_timeout_ms` |
| `net register conn / net record rx / net record tx / net close conn` | Registrerar accepterade sockets, spårar byte-räknare/tidsstämplar och stänger anslutningar |
| `net evict idle : NetSupervisor -> Int -> (NetSupervisor, [Int])` | Stänger och rensar ut anslutningar som varit inaktiva längre än `idle_timeout_ms` |
| `net poll fd : Int -> Bool -> Int -> NetEvent` | Icke-blockerande `wait fd`-brygga som ger `NetEvReadyRead`, `NetEvReadyWrite`, `NetEvTimeout` eller `NetEvError` |
| `net tcp echo step : String -> Int -> (Int, String)` | Komplett TCP loopback-steg från ända till ända (`listen/connect/accept/supervise/echo`) |

---

## 4. Praktiska recept i tabellform

### Recept 1: Huvudflöde med `net_agent`

Lägg märke till hur `=`-tecknen och transformationsstegen linjeras som en ren tabell:

```ridgun
import net_agent

fn :: supervisar clientes () => (Int, [Int])
      supervisar clientes =
        s0        = net supervisor new 100 5000
        (s1, _)   = net register conn s0 10 "10.0.0.1" 51000 1000
        (s2, _)   = net register conn s1 11 "10.0.0.2" 51001 6500
        (s3, exp) = net evict idle s2 7000
        (net active count s3, exp)
```

### Recept 2: Säker komposition utan sidoeffekter

Varje funktion i lib:en `net_agent` kan kombineras fritt med övriga 32 libs i `ridgun-libs`:

```ridgun
import net_agent

fn :: probar puente tcp supervisado () => (Int, String)
      probar puente tcp supervisado =
        net tcp echo step "ping-supervisado" 1000
```

---

## 5. Under huven: prestanda, RMM-minne och garantier

- **Algoritmisk garanti och säkerhet**: Automatiskt skydd mot deskriptoruttömning (`max_conns`), deterministisk utrensning av inaktiva anslutningar och garanterad stängning av sockets i `net tcp echo step`.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test_net_agent.rg`.
