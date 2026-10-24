# Kapitel 23: Lib:en `io` — Typade `IoResult`-fel, `with timeout`-I/O och Processer

## 1. Varför finns lib:en `io`?

Låt oss vara ärliga: ett `read()`-anrop eller en barnprocess utan tidsgräns (`timeout`) är en öppen inbjudan för en enda hängande resurs att tömma alla arbetare i din server.

Lib:en **`io`** modellerar varje systemoperation med explicita ADT:er (`IoError`, `IoResult[A]`), kombinerar icke-blockerande `ppoll` med Ridguns lexikala `with timeout wait_ms do`-kvoter och erbjuder mixfix-operatorerna `read fd ... timeout` och `write fd ... timeout`.

---

## 2. Paket, import och arkitektur helt utan `libc`

I `ridgun-libs` är **`io`** en förstklassig **lib** placerad i `src/main/ridgun/lib/io.rg` (domän `IO`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/io.rglib` | Portabel distribution och direkt import med `import io` |
| **Kompilerat arkiv** | `target/io.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libio.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import io` överst och anropar funktionerna med mellanslag eller understreck.

---

## 3. Snabbreferens för `io`-API:et

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `type IoError / type IoResult[A]` | `IoNotFound | IoPermission | IoTimeout | IoRefused | IoReset | IoEOF | IoInvalid | IoSysError` |
| `io read with timeout / io write with timeout` | Icke-blockerande läsning/skrivning på deskriptor begränsad av `wait_ms` |
| `read fd N max M timeout T / write fd N data S timeout T` | Ergonomiska mixfix-operatorer (`op ::`) för tidsbegränsad deskriptor-I/O |
| `io read file / io write file / io read lines` | Säkra fil- och radströmsfunktioner som returnerar `IoResult` |
| `exec with timeout : String -> Int -> IoResult[ProcStatus]` | Kör ett externt kommando begränsat av en lexikal `with timeout`-kvot |

---

## 4. Praktiska recept i tabellform

### Recept 1: Huvudflöde med `io`

Lägg märke till hur `=`-tecknen och transformationsstegen linjeras som en ren tabell:

```ridgun
import io

fn :: leer peticion segura (fd : Int) => String
      leer peticion segura fd =
        res = read fd fd max 4096 timeout 250
        io unwrap or res ""
```

### Recept 2: Säker komposition utan sidoeffekter

Varje funktion i lib:en `io` kan kombineras fritt med övriga 32 libs i `ridgun-libs`:

```ridgun
import io

fn :: describir fallo () => String
      describir fallo =
        format io error (IoTimeout "read" 250)
```

---

## 5. Under huven: prestanda, RMM-minne och garantier

- **Algoritmisk garanti och säkerhet**: Ingen läsning, skrivning eller barnprocess som körs via `io` med en `wait_ms`-kvot kan någonsin blockera den anropande tråden eller aktören på obestämd tid.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test_io.rg`.
