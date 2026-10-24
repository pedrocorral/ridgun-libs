# Kapitel 16: Lib:en `cli` — Flaggor, Alternativ, `--`-barriär, Underkommandon och Miljövariabler

## 1. Varför finns lib:en `cli`?

Låt oss vara ärliga: att tolka `argv` för hand börjar alltid som en oskyldig loop och går sönder så fort någon skickar kombinerade `-la`-flaggor, `--port=9090` eller `--` följt av ett filnamn som börjar med bindestreck.

Lib:en **`cli`** hanterar långa flaggor (`--verbose`), korta flaggor (`-v`), kombinerade kortflaggor (`-la`), värdealternativ (`--port=8080`, `--port 8080`, `-p 8080`), POSIX-barriären `--`, positionella argument, underkommandon och typade miljövariabler.

---

## 2. Paket, import och arkitektur helt utan `libc`

I `ridgun-libs` är **`cli`** en förstklassig **lib** placerad i `src/main/ridgun/lib/cli.rg` (domän `CLI`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/cli.rglib` | Portabel distribution och direkt import med `import cli` |
| **Kompilerat arkiv** | `target/cli.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libcli.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import cli` överst och anropar funktionerna med mellanslag eller understreck.

---

## 3. Snabbreferens för `cli`-API:et

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `cli has flag : [String] -> String -> String -> Bool` | Detekterar `--long`, `-s` eller kombinerade `-xyz` före `--` |
| `cli get opt / cli get int opt` | Extraherar sträng- eller heltalsalternativ (`--k=v`, `--k v`, `-k v`) med standardvärde |
| `cli positionals / cli subcommand` | Samlar in positionella argument (inklusive allt efter `--`) |
| `env get or / env get int or / env get bool or` | Läser miljövariabler med typad konvertering och reservvärden |

---

## 4. Praktiska recept i tabellform

### Recept 1: Huvudflöde med `cli`

Lägg märke till hur `=`-tecknen och transformationsstegen linjeras som en ren tabell:

```ridgun
import cli

fn :: analizar comando (args : [String]) => (String, Bool, Int, [String])
      analizar comando args =
        sub   = cli subcommand args
        all_f = cli has flag args "--all" "-a"
        port  = cli get int opt args "--port" "-p" 8080
        arch  = cli positionals args ["--port", "-p"]
        (sub, all_f, port, arch)
```

### Recept 2: Säker komposition utan sidoeffekter

Varje funktion i lib:en `cli` kan kombineras fritt med övriga 32 libs i `ridgun-libs`:

```ridgun
import cli

fn :: leer config entorno () => (Int, Bool)
      leer config entorno =
        workers = env get int or "SOLSTICE_WORKERS" 4
        debug   = env get bool or "SOLSTICE_DEBUG" False
        (workers, debug)
```

---

## 5. Under huven: prestanda, RMM-minne och garantier

- **Algoritmisk garanti och säkerhet**: Strikt efterlevnad av POSIX-barriären `--`: inget argument till höger om `--` tolkas någonsin som en flagga.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test_cli.rg`.
