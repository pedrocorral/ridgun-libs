# Kapitel 17: Lib:en `path` — POSIX-normalisering (`path clean`) och Skydd mot Path Traversal

## 1. Varför finns lib:en `path`?

Låt oss vara ärliga: att slå ihop sökvägar med `base + "/" + fil` utan att rensa `..`-segment och kontrollera gränser är en öppen inbjudan till en `../../etc/passwd`-attack.

Lib:en **`path`** implementerar lexikal POSIX-normalisering (`path clean`), säker sammanslagning (`path join`), komponentextrahering (`dirname`, `basename`, `stem`, `ext`, `replace ext`) och säkerhetspredikatet **`path is safe subpath`** (`VUL-INJ-001`) mot *path traversal*.

---

## 2. Paket, import och arkitektur helt utan `libc`

I `ridgun-libs` är **`path`** en förstklassig **lib** placerad i `src/main/ridgun/lib/path.rg` (domän `PATH`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/path.rglib` | Portabel distribution och direkt import med `import path` |
| **Kompilerat arkiv** | `target/path.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libpath.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import path` överst och anropar funktionerna med mellanslag eller understreck.

---

## 3. Snabbreferens för `path`-API:et

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `path clean / path join / path join list` | Slår ihop `//`, `.` och `..` lexikalt och förenar sökvägssegment |
| `path dirname / path basename / path split` | Delar upp en sökväg i föräldrakatalog och sista filnamnskomponent |
| `path ext / path stem / path replace ext` | Extraherar eller byter filändelse (behandlar `.bashrc` som basnamn `.bashrc`, ändelse `""`) |
| `path is safe subpath : String -> String -> Bool` | Verifierar att `rel` stannar strikt inom `base_dir` och saknar NUL-bytes |

---

## 4. Praktiska recept i tabellform

### Recept 1: Huvudflöde med `path`

Lägg märke till hur `=`-tecknen och transformationsstegen linjeras som en ren tabell:

```ridgun
import path

fn :: resolver archivo estatico (raiz : String) (peticion : String) => (Bool, String)
      resolver archivo estatico raiz peticion =
        seguro = path is safe subpath raiz peticion
        ruta   = path join raiz peticion
        (seguro, ruta)
```

### Recept 2: Säker komposition utan sidoeffekter

Varje funktion i lib:en `path` kan kombineras fritt med övriga 32 libs i `ridgun-libs`:

```ridgun
import path

fn :: cambiar salida a objeto (fuente : String) => (String, String, String)
      cambiar salida a objeto fuente =
        dir = path dirname fuente
        nom = path stem fuente
        obj = path replace ext (path clean fuente) ".rglib"
        (dir, nom, obj)
```

---

## 5. Under huven: prestanda, RMM-minne och garantier

- **Algoritmisk garanti och säkerhet**: `path is safe subpath` avvisar absoluta sökvägar, NUL-bytes och alla `..`-sekvenser som försöker lämna baskatalogen eller nå en syskonkatalog (`/srv/www-secret`).
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test_path.rg`.
