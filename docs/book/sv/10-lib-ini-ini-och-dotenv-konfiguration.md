# Kapitel 10: Lib:en `ini` — Sektionsindelade `.ini`-filer, `.env` och Variabelinterpolering

## 1. Varför finns lib:en `ini`?

Låt oss vara ärliga: `.env`- och `.ini`-filer verkar triviala tills någon skriver `export KEY="värde # med brädgård"`, kommentarer med `;` i slutet av raden eller korsreferenser mellan variabler.

Lib:en **`ini`** tolkar sektionsindelade `.ini`-filer (`[database]`) och `.env`-filer med `export`-prefix, bevarar `#` och `;` inuti citerade värden och löser upp variabelinterpoleringar i `dotenv parse`.

---

## 2. Paket, import och arkitektur helt utan `libc`

I `ridgun-libs` är **`ini`** en förstklassig **lib** placerad i `src/main/ridgun/lib/ini.rg` (domän `INI`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/ini.rglib` | Portabel distribution och direkt import med `import ini` |
| **Kompilerat arkiv** | `target/ini.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libini.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import ini` överst och anropar funktionerna med mellanslag eller understreck.

---

## 3. Snabbreferens för `ini`-API:et

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `ini parse / ini stringify` | Tolkar sektionsindelad `.ini`-text till `IniDoc` och serialiserar tillbaka |
| `ini get / ini get int / ini get bool / ini set` | Typad uppslagning via sektion+nyckel (`""` för global sektion) och oföränderlig uppdatering |
| `ini sections / ini section map` | Listar alla sektionsnamn eller extraherar en sektions `[String String]`-mapp |
| `dotenv parse` | Tolkar `.env`-rader (`export K=V`, citattecken, kommentarer och variabelexpansion) |

---

## 4. Praktiska recept i tabellform

### Recept 1: Huvudflöde med `ini`

Lägg märke till hur `=`-tecknen och transformationsstegen linjeras som en ren tabell:

```ridgun
import ini

fn :: cargar base de datos (texto_ini : String) => (String, Int, Bool)
      cargar base de datos texto_ini =
        doc  = ini parse texto_ini
        host = ini get doc "database" "host" "localhost"
        port = ini get int doc "database" "port" 5432
        pool = ini get bool doc "database" "pool" True
        (host, port, pool)
```

### Recept 2: Säker komposition utan sidoeffekter

Varje funktion i lib:en `ini` kan kombineras fritt med övriga 32 libs i `ridgun-libs`:

```ridgun
import ini

fn :: actualizar puerto (doc : IniDoc) (nuevo : String) => String
      actualizar puerto doc nuevo =
        doc2 = ini set doc "database" "port" nuevo
        ini stringify doc2
```

---

## 5. Under huven: prestanda, RMM-minne och garantier

- **Algoritmisk garanti och säkerhet**: Fullt bevarande av `#` och `;` inuti enkla eller dubbla citattecken samt flexibel boolesk tolkning (`true/1/yes/on` kontra `false/0/no/off`).
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test_ini.rg`.
