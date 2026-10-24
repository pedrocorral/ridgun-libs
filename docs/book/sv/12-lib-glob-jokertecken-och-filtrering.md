# Kapitel 12: Lib:en `glob` — Jokerteckenmönster (`*`, `?`, `[a-z]`) och Listfiltrering

## 1. Varför finns lib:en `glob`?

Låt oss vara ärliga: att dra igång en hel regex-motor bara för att kontrollera om ett filnamn matchar `*.rg` eller `test_[0-9]*.rg` är att skjuta mygg med kanon.

Lib:en **`glob`** implementerar exakt matchning av skal-jokertecken (`*`, `?`, `[a-z]`-intervall, negerade `[!0-9]` / `[^a-z]`-klasser), skiftlägesokänslig matchning (`glob match ci`) och listfiltrering.

---

## 2. Paket, import och arkitektur helt utan `libc`

I `ridgun-libs` är **`glob`** en förstklassig **lib** placerad i `src/main/ridgun/lib/glob.rg` (domän `GLOB`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/glob.rglib` | Portabel distribution och direkt import med `import glob` |
| **Kompilerat arkiv** | `target/glob.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libglob.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import glob` överst och anropar funktionerna med mellanslag eller understreck.

---

## 3. Snabbreferens för `glob`-API:et

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `glob match / glob match ci` | Skiftlägeskänslig och skiftlägesokänslig glob-mönstermatchning |
| `glob filter / glob any match` | Filtrerar `[String]` till matchande element eller testar om något mönster i en lista matchar |
| `glob has magic` | Detekterar om en sträng innehåller jokertecken (`*`, `?`, `[`) |

---

## 4. Praktiska recept i tabellform

### Recept 1: Huvudflöde med `glob`

Lägg märke till hur `=`-tecknen och transformationsstegen linjeras som en ren tabell:

```ridgun
import glob

fn :: seleccionar fuentes ridgun (archivos : [String]) => [String]
      seleccionar fuentes ridgun archivos =
        glob filter "test_[a-z]*.rg" archivos
```

### Recept 2: Säker komposition utan sidoeffekter

Varje funktion i lib:en `glob` kan kombineras fritt med övriga 32 libs i `ridgun-libs`:

```ridgun
import glob

fn :: es ruta excluida (ruta : String) => Bool
      es ruta excluida ruta =
        glob any match ["*.tmp", "*.bak", "target/*"] ruta
```

---

## 5. Under huven: prestanda, RMM-minne och garantier

- **Algoritmisk garanti och säkerhet**: Automatisk sammanslagning av på varandra följande asterisker (`***` $\rightarrow$ `*`) för att undvika onödig backtracking samt säker hantering av oavslutade `[`-klammrar.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test_glob.rg`.
