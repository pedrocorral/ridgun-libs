# Kapitel 09: Lib:en `csv` — RFC 4180 CSV/TSV-Tillståndsmaskin och Kolumnindexerade Tabeller

## 1. Varför finns lib:en `csv`?

Låt oss vara ärliga: alla tror att CSV-tolkning bara är `str split rad ","`... tills det dyker upp ett citerat fält med ett kommatecken inuti, dubbla citattecken `""` eller en radbrytning `\r\n` mitt i en cell.

Lib:en **`csv`** implementerar en komplett **RFC 4180**-tillståndsmaskin för CSV och TSV, smart serialisering med citattecken och typen `CsvTable` för kolumn- och raduppslagning via rubriknamn.

---

## 2. Paket, import och arkitektur helt utan `libc`

I `ridgun-libs` är **`csv`** en förstklassig **lib** placerad i `src/main/ridgun/lib/csv.rg` (domän `CSV`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/csv.rglib` | Portabel distribution och direkt import med `import csv` |
| **Kompilerat arkiv** | `target/csv.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libcsv.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import csv` överst och anropar funktionerna med mellanslag eller understreck.

---

## 3. Snabbreferens för `csv`-API:et

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `csv parse / tsv parse / csv parse with` | Tolkar CSV/TSV-text (inklusive flerradiga citerade fält och `""`) till `[[String]]` |
| `csv stringify / tsv stringify` | Serialiserar `[[String]]` och citerar endast celler med avgränsare, citattecken eller radbrytningar |
| `csv parse table / csv get cell / csv col` | Rubrikindexerad `CsvTable`-uppslagning via `(rad, kolumnnamn)` eller hel kolumn |
| `csv row to kv / csv table to kv list` | Konverterar tabellrader till `[String String]`-mappar nycklade efter rubrik |

---

## 4. Praktiska recept i tabellform

### Recept 1: Huvudflöde med `csv`

Lägg märke till hur `=`-tecknen och transformationsstegen linjeras som en ren tabell:

```ridgun
import csv

fn :: extraer columna precios (raw_csv : String) => ([String], String)
      extraer columna precios raw_csv =
        tabla   = csv parse table raw_csv
        precios = csv col tabla "precio"
        primero = csv get cell tabla 0 "producto" "desconocido"
        (precios, primero)
```

### Recept 2: Säker komposition utan sidoeffekter

Varje funktion i lib:en `csv` kan kombineras fritt med övriga 32 libs i `ridgun-libs`:

```ridgun
import csv

fn :: exportar informe () => String
      exportar informe =
        filas = [["id", "nota"], ["1", "Contiene, coma"], ["2", "Dijo "hola""]]
        csv stringify filas
```

---

## 5. Under huven: prestanda, RMM-minne och garantier

- **Algoritmisk garanti och säkerhet**: Exakt hantering av `\r\n` och `\n` både inom och utanför citattecken samt förlustfria rundresor med `csv parse (csv stringify rader)`.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test_csv.rg`.
