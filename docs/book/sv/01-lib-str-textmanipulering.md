# Kapitel 01: Lib:en `str` — Textmanipulering, Sökning och Tabelljustering

## 1. Varför finns lib:en `str`?

Låt oss vara ärliga: att manipulera strängar i C med `strtok` och `strncpy` är att vandra genom ett minfält av buffertspill och `NULL`-pekare, och i andra språk importerar man ofta externa paket bara för att fylla ut kolumner i $O(\log N)$.

Lib:en **`str`** tillhandahåller rena, oföränderliga primitiver för att söka, trimma, dela upp, slå samman, ändra skiftläge, upprepa med binär fördubbling $O(\log N)$ och fylla ut kolumner.

---

## 2. Paket, import och arkitektur helt utan `libc`

I `ridgun-libs` är **`str`** en förstklassig **lib** placerad i `src/main/ridgun/lib/str.rg` (domän `STR`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/str.rglib` | Portabel distribution och direkt import med `import str` |
| **Kompilerat arkiv** | `target/str.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libstr.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import str` överst och anropar funktionerna med mellanslag eller understreck.

---

## 3. Snabbreferens för `str`-API:et

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `str index of : String -> String -> Int` | Första indexet för delsträngen (`-1` om den saknas / `0` om tom) |
| `str contains / str starts with / str ends with` | `Bool`-predikat för delsträng, prefix och suffix |
| `str trim / str trim left / str trim right` | Tar bort blanktecken i ASCII (` `, `\t`, `\n`, `\r`) |
| `str split / str lines / str words / str join` | Delar upp till `[String]` och slår ihop listor med avgränsare |
| `str replace / str to upper / str to lower` | Icke-överlappande ersättning och ASCII-skiftlägeskonvertering |
| `str repeat / str pad left / str pad right` | $O(\log N)$-upprepning och kolumnutfyllnad till fast bredd |

---

## 4. Praktiska recept i tabellform

### Recept 1: Huvudflöde med `str`

Lägg märke till hur `=`-tecknen och transformationsstegen linjeras som en ren tabell:

```ridgun
import str

fn :: normalizar cabecera (raw : String) => String
      normalizar cabecera raw =
        limpia = str to lower (str trim raw)
        partes = str words limpia
        slug   = str join partes "-"
        str pad right slug 24 "."
```

### Recept 2: Säker komposition utan sidoeffekter

Varje funktion i lib:en `str` kan kombineras fritt med övriga 32 libs i `ridgun-libs`:

```ridgun
import str

fn :: extraer dominio (correo : String) => String
      extraer dominio correo =
        pos = str index of correo "@"
        | pos < 0   = "sin-dominio"
        | otherwise =
          partes = str split correo "@"
          str replace (str to lower correo) "@" " en "
```

---

## 5. Under huven: prestanda, RMM-minne och garantier

- **Algoritmisk garanti och säkerhet**: $O(\log N)$-upprepning via binär strängfördubbling, säker hantering av tomma söksträngar och noll mutering på plats.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test_str.rg`.
