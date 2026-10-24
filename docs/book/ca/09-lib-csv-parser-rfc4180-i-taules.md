# Capítol 09: La lib `csv` — Analitzador d'Estats RFC 4180 per a CSV/TSV i Taules Indexades

## 1. Per què existeix la lib `csv`?

Siguem sincers: tothom es pensa que analitzar un CSV és fer `str split linia ","`... fins que apareix un camp entre cometes amb una coma a dins, cometes escapades `""` o un salt de línia `\r\n` al mig d'una cel·la.

La lib **`csv`** implementa una màquina d'estats completa conforme a **RFC 4180** per a CSV i TSV, serialització automàtica amb cometes intel·ligents i el tipus `CsvTable` per consultar columnes i files per nom de capçalera.

---

## 2. Artefactes, importació i arquitectura sense `libc`

A `ridgun-libs`, **`csv`** és una **lib** de primera classe situada a `src/main/ridgun/lib/csv.rg` (domini `CSV`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/csv.rglib` | Distribució i importació directa amb `import csv` |
| **Fitxer compilat** | `target/csv.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libcsv.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Per fer servir aquesta lib en qualsevol fitxer `.rg`, n'hi ha prou de declarar `import csv` a la capçalera i cridar les seves funcions amb espais o guions baixos indistintament.

---

## 3. Referència ràpida de l'API de `csv`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `csv parse / tsv parse / csv parse with` | Analitza text CSV/TSV (incloent-hi cel·les multilínia i escapaments `""`) en `[[String]]` |
| `csv stringify / tsv stringify` | Serialitza `[[String]]` posant cometes només a cel·les amb delimitadors, cometes o salts |
| `csv parse table / csv get cell / csv col` | Consulta sobre `CsvTable` indexada per capçalera `(fila, nom_col)` o columna completa |
| `csv row to kv / csv table to kv list` | Converteix files tabulars en diccionaris `[String String]` indexats per capçalera |

---

## 4. Receptes pràctiques en estil tabular

### Recepta 1: Flux principal amb `csv`

Observa com els signes `=` i els passos de transformació queden alineats com una taula neta:

```ridgun
import csv

fn :: extraer columna precios (raw_csv : String) => ([String], String)
      extraer columna precios raw_csv =
        tabla   = csv parse table raw_csv
        precios = csv col tabla "precio"
        primero = csv get cell tabla 0 "producto" "desconocido"
        (precios, primero)
```

### Recepta 2: Composició segura i sense efectes laterals

Tota funció de la lib `csv` és componible amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import csv

fn :: exportar informe () => String
      exportar informe =
        filas = [["id", "nota"], ["1", "Contiene, coma"], ["2", "Dijo "hola""]]
        csv stringify filas
```

---

## 5. Sota el capó: rendiment, memòria RMM i garanties

- **Garantia algorísmica i de seguretat**: Suport exacte de salts `\r\n` i `\n` tant fora com dins de cometes, i zero pèrdua de dades en viatges d'anada i tornada `csv parse (csv stringify files)`.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test_csv.rg`.
