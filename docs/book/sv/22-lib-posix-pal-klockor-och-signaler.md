# Kapitel 22: Lib:en `posix` — Plattformslager (PAL), Klockor, Signaler och CSPRNG

## 1. Varför finns lib:en `posix`?

Låt oss vara ärliga: flaggor som `O_CREAT` och `O_NONBLOCK` eller syscall-nummer skiljer sig mellan Linux, macOS och arkitekturer (`X86_64` mot `Arm64`), och i C löser man det med en oläslig `#ifdef`-djungel.

Lib:en **`posix`** implementerar Ridguns tvåskikts **Platform Abstraction Layer (PAL)** med tabulära vakter över `sys os` (`Linux | MacOS | Windows`) och `sys arch` (`X86_64 | Arm64 | RiscV64`), samt deskriptor-polling (`wait fd`), monotona klockor (`RGF-017`), signaler (`RGF-018`) och CSPRNG (`sys random bytes`).

---

## 2. Paket, import och arkitektur helt utan `libc`

I `ridgun-libs` är **`posix`** en förstklassig **lib** placerad i `src/main/ridgun/lib/posix.rg` (domän `POSIX`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/posix.rglib` | Portabel distribution och direkt import med `import posix` |
| **Kompilerat arkiv** | `target/posix.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libposix.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import posix` överst och anropar funktionerna med mellanslag eller understreck.

---

## 3. Snabbreferens för `posix`-API:et

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `pal open create trunc wr / pal o nonblock` | Målmedveten OS-flaggöversättning via `sys os` (`Linux | MacOS | Windows`) |
| `wait fd : Int -> Int -> Int -> PollStatus` | Pollar en deskriptor och returnerar `PollReady`, `PollTimeout` eller `PollError errno` |
| `clock monotonic ms / clock monotonic ns / clock wall ms` | Monotona klockor och UTC-väggklocka i millisekunder (`RGF-017`) |
| `signal watch / signal poll / sys random bytes` | Icke-blockerande signal-polling (`SIGINT`, `SIGTERM`) och CSPRNG-bytes från kärnan |
| `read text / write text / file exists / run cmd` | Högnivå-fil-I/O, katalogoperationer och barnprocess-wrappers |

---

## 4. Praktiska recept i tabellform

### Recept 1: Huvudflöde med `posix`

Lägg märke till hur `=`-tecknen och transformationsstegen linjeras som en ren tabell:

```ridgun
import posix

fn :: medir operacion () => (Int, Int)
      medir operacion =
        t0  = clock monotonic ms
        rnd = len (sys random bytes 32)
        t1  = clock monotonic ms
        (rnd, t1 - t0)
```

### Recept 2: Säker komposition utan sidoeffekter

Varje funktion i lib:en `posix` kan kombineras fritt med övriga 32 libs i `ridgun-libs`:

```ridgun
import posix

fn :: esperar lectura (fd : Int) => Bool
      esperar lectura fd =
        est = wait fd fd poll_in 100
        est == PollReady
```

---

## 5. Under huven: prestanda, RMM-minne och garantier

- **Algoritmisk garanti och säkerhet**: Grenar av `sys os` och `sys arch` som inte matchar målplattformen elimineras statiskt vid kompilering (Dead-Code Elimination) av `ridgunc`.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test_posix.rg`.
