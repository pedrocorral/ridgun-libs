# Capítulo 09: A lib `csv` — Analizador de Estados RFC 4180 para CSV/TSV e Táboas Indexadas

## 1. Por que existe a lib `csv`?

Sexamos sinceros: todo o mundo cre que analizar un CSV é facer `str split lina ","`... ata que aparece un campo entre comiñas cunha coma dentro, comiñas escapadas `""` ou un salto de liña `\r\n` no medio dunha cela.

A lib **`csv`** implementa unha máquina de estados completa conforme a **RFC 4180** para CSV e TSV, serialización automática con comiñas intelixentes e o tipo `CsvTable` para consultar columnas e filas por nome de cabeceira.

---

## 2. Artefactos, importación e arquitectura sen `libc`

En `ridgun-libs`, **`csv`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/csv.rg` (dominio `CSV`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/csv.rglib` | Distribución e importación directa con `import csv` |
| **Ficheiro compilado** | `target/csv.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libcsv.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import csv` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

---

## 3. Referencia rápida da API de `csv`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `csv parse / tsv parse / csv parse with` | Analiza texto CSV/TSV (incluíndo celas multiliña e escapes `""`) en `[[String]]` |
| `csv stringify / tsv stringify` | Serializa `[[String]]` entrecomiñando só celas con delimitadores, comiñas ou saltos |
| `csv parse table / csv get cell / csv col` | Consulta sobre `CsvTable` indexada por cabeceira `(fila, nome_col)` ou columna completa |
| `csv row to kv / csv table to kv list` | Converte filas tabulares en dicionarios `[String String]` indexados por cabeceira |

---

## 4. Receitas prácticas en estilo tabular

### Receita 1: Fluxo principal con `csv`

Observa como os signos `=` e os pasos de transformación quedan aliñados coma unha táboa limpa:

```ridgun
import csv

fn :: extraer columna precios (raw_csv : String) => ([String], String)
      extraer columna precios raw_csv =
        tabla   = csv parse table raw_csv
        precios = csv col tabla "precio"
        primero = csv get cell tabla 0 "producto" "desconocido"
        (precios, primero)
```

### Receita 2: Composición segura e sen efectos laterais

Toda función da lib `csv` é compoñible co resto das 32 libs de `ridgun-libs`:

```ridgun
import csv

fn :: exportar informe () => String
      exportar informe =
        filas = [["id", "nota"], ["1", "Contiene, coma"], ["2", "Dijo "hola""]]
        csv stringify filas
```

---

## 5. Baixo o capó: rendemento, memoria RMM e garantías

- **Garantía algorítmica e de seguridade**: Soporte exacto de saltos `\r\n` e `\n` tanto fóra coma dentro de comiñas, e cero perda de datos en viaxes de ida e volta `csv parse (csv stringify filas)`.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test_csv.rg`.
