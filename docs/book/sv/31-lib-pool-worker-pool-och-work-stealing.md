# Kapitel 31: Lib:en `pool` — Begränsad Worker-pool, Round-Robin och Work-Stealing

## 1. Varför finns lib:en `pool`?

Låt oss vara ärliga: att starta en ny tråd eller aktör för varje inkommande anrop utan övre gräns garanterar att en trafiktopp tömmer serverns minne på några sekunder.

Lib:en **`pool`** tillhandahåller en begränsad uppgiftsfördelare med **explicit mottryck** (`PoolAccept`, `PoolRejectFull`), balanserad uppdelning i $K$ filer (`pool partition`), ombalansering med **work-stealing** (`pool steal rebalance`) och parallell exekvering över inbyggda aktörer.

---

## 2. Paket, import och arkitektur helt utan `libc`

I `ridgun-libs` är **`pool`** en förstklassig **lib** placerad i `src/main/ridgun/lib/pool.rg` (domän `AGENT`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/pool.rglib` | Portabel distribution och direkt import med `import pool` |
| **Kompilerat arkiv** | `target/pool.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libpool.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import pool` överst och anropar funktionerna med mellanslag eller understreck.

---

## 3. Snabbreferens för `pool`-API:et

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `pool new : Int -> Int -> PoolState` | Skapar en begränsad pool med `workers` filer och `max_queue` i kökapacitet |
| `pool submit : PoolState -> PoolTask -> (PoolState, PoolDecision)` | Köar en uppgift med round-robin eller returnerar `PoolRejectFull` vid mättnad |
| `pool partition / pool steal rebalance` | Delar upp batcher över $K$ arbetare och stjäl hälften av en överbelastad kö till en ledig arbetare |
| `pool map sum / pool parallel sum2` | Fördelar arbetslaster parallellt över inbyggda `agent`-arbetare |

---

## 4. Praktiska recept i tabellform

### Recept 1: Huvudflöde med `pool`

Lägg märke till hur `=`-tecknen och transformationsstegen linjeras som en ren tabell:

```ridgun
import pool

fn :: encolar con contrapresion () => (Int, Int)
      encolar con contrapresion =
        p0        = pool new 4 16
        tarea     = PoolTask 1 100 "indexar-bloque"
        (p1, dec) = pool submit p0 tarea
        (pool queued p1, pool accepted p1)
```

### Recept 2: Säker komposition utan sidoeffekter

Varje funktion i lib:en `pool` kan kombineras fritt med övriga 32 libs i `ridgun-libs`:

```ridgun
import pool

fn :: sumar en paralelo () => Int
      sumar en paralelo =
        pool parallel sum2 [10, 20, 30] [40, 50, 60]
```

---

## 5. Under huven: prestanda, RMM-minne och garantier

- **Algoritmisk garanti och säkerhet**: Strikt begränsad kökapacitet (`queued <= max_queue`) för att skydda minnet vid belastningstoppar samt deterministisk fördelning mellan arbetare.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test_pool.rg`.
