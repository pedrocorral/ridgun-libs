# Kapitel 20: Lib:en `log` — Strukturerad NDJSON-loggning och Automatisk Sekretessmaskering

## 1. Varför finns lib:en `log`?

Låt oss vara ärliga: att skriva ut anropsfält till en loggfil och veckor senare upptäcka att `password`, `api_key` eller `authorization` sparats i klartext i logghanteraren är en klassisk säkerhetsincident.

Lib:en **`log`** erbjuder allvarlighetsfiltrering (`DEBUG`, `INFO`, `WARN`, `ERROR`), text- och **NDJSON-formatering** samt **automatisk maskering av känsliga nycklar** (`password`, `secret`, `token`, `api_key`, `authorization`, `cookie`, `private_key` $\rightarrow$ `"[REDACTED]"`, vilket motverkar `VUL-LOG-001`).

---

## 2. Paket, import och arkitektur helt utan `libc`

I `ridgun-libs` är **`log`** en förstklassig **lib** placerad i `src/main/ridgun/lib/log.rg` (domän `LOG`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/log.rglib` | Portabel distribution och direkt import med `import log` |
| **Kompilerat arkiv** | `target/log.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/liblog.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import log` överst och anropar funktionerna med mellanslag eller understreck.

---

## 3. Snabbreferens för `log`-API:et

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `log level rank / log should emit` | Jämför loggnivåer (`DEBUG=10`, `INFO=20`, `WARN=30`, `ERROR=40`) mot inställd tröskel |
| `log is sensitive key / log redact fields` | Ersätter skiftlägesokänsligt hemliga värden med `"[REDACTED]"` |
| `log format text / log format json` | Formaterar `nyckel=värde`-text eller RFC 8259 NDJSON med automatisk sekretessmaskering |

---

## 4. Praktiska recept i tabellform

### Recept 1: Huvudflöde med `log`

Lägg märke till hur `=`-tecknen och transformationsstegen linjeras som en ren tabell:

```ridgun
import log

fn :: auditar login (usuario : String) (clave : String) => String
      auditar login usuario clave =
        campos = [("user", usuario), ("password", clave), ("ip", "10.0.0.1")]
        log format json "INFO" "intento de acceso" campos
```

### Recept 2: Säker komposition utan sidoeffekter

Varje funktion i lib:en `log` kan kombineras fritt med övriga 32 libs i `ridgun-libs`:

```ridgun
import log

fn :: emitir si procede (umbral : String) (nivel : String) (msg : String) => String
      emitir si procede umbral nivel msg =
        | log should emit umbral nivel = log format text nivel msg [("service", "solstice")]
        | otherwise                    = ""
```

---

## 5. Under huven: prestanda, RMM-minne och garantier

- **Algoritmisk garanti och säkerhet**: Både `log format text` och `log format json` kör alltid fälten genom `log redact fields` före serialisering, vilket garanterar att inga hemligheter läcker av misstag.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test_log.rg`.
