# Kapitel 11: Lib:en `regex` — Reguljära Uttryck med Thompson-NFA i Linjär Tid $O(N \cdot M)$

## 1. Varför finns lib:en `regex`?

Låt oss vara ärliga: regex-motorer med *backtracking* har orsakat ökända globala driftstopp (som hos Cloudflare och StackOverflow) när ett mönster som `(a+)+b` matas med trettio `a` i rad och exploderar i exponentiell tid $O(2^N)$.

Lib:en **`regex`** kompilerar reguljära uttryck (`.`, `*`, `+`, `?`, `|`, `()`, `[a-z]`, `[^...]`, `^`, `$`, `\d`, `\w`, `\s`) till en **Thompson-NFA** och stegar tillståndsmängden i strikt linjär tid **$O(N \cdot M)$**, vilket gör **ReDoS-attacker matematiskt omöjliga**.

---

## 2. Paket, import och arkitektur helt utan `libc`

I `ridgun-libs` är **`regex`** en förstklassig **lib** placerad i `src/main/ridgun/lib/regex.rg` (domän `REGEX`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/regex.rglib` | Portabel distribution och direkt import med `import regex` |
| **Kompilerat arkiv** | `target/regex.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libregex.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import regex` överst och anropar funktionerna med mellanslag eller understreck.

---

## 3. Snabbreferens för `regex`-API:et

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `regex match / regex is match` | Helsträngsmatchning och delsträngssökning i linjär tid $O(N \cdot M)$ |
| `regex find / regex find all` | Extraherar den första eller alla icke-överlappande matchande delsträngar |
| `regex replace / regex replace all` | Ersätter den första eller alla regex-träffar med en ersättningssträng |
| `regex split / regex escape` | Delar upp text med en regex-avgränsare och kodar metatecken |

---

## 4. Praktiska recept i tabellform

### Recept 1: Huvudflöde med `regex`

Lägg märke till hur `=`-tecknen och transformationsstegen linjeras som en ren tabell:

```ridgun
import regex

fn :: extraer codigos postales (texto : String) => [String]
      extraer codigos postales texto =
        regex find all "\\d+" texto
```

### Recept 2: Säker komposition utan sidoeffekter

Varje funktion i lib:en `regex` kan kombineras fritt med övriga 32 libs i `ridgun-libs`:

```ridgun
import regex

fn :: censurar telefonos (comentario : String) => (Bool, String)
      censurar telefonos comentario =
        tiene = regex is match "\\d+-\\d+" comentario
        limpio = regex replace all "\\d+-\\d+" comentario "[TELEFONO]"
        (tiene, limpio)
```

---

## 5. Under huven: prestanda, RMM-minne och garantier

- **Algoritmisk garanti och säkerhet**: NFA-tillståndssimulering utan okontrollerad stackrekursion och garanterad $O(N \cdot M)$-körtid även för patologiska `(a+)+b`-mönster.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test_regex.rg`.
