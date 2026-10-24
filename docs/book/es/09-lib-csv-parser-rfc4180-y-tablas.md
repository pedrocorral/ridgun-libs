# Capítulo 09: La lib `csv` — Analizador de Estados RFC 4180 para CSV/TSV y Tablas Indexadas

## 1. ¿Por qué existe la lib `csv`?

Seamos sinceros: todo el mundo cree que parsear un CSV es hacer `str split linea ","`... hasta que aparece un campo entre comillas con una coma dentro, comillas escapadas `""` o un salto de línea `\r\n` en mitad de una celda.

La lib **`csv`** implementa una máquina de estados completa conforme a **RFC 4180** para CSV y TSV, serialización automática con entrecomillado inteligente y el tipo `CsvTable` para consultar columnas y filas por nombre de cabecera.

---

## 2. Artefactos, importación y arquitectura sin `libc`

En `ridgun-libs`, **`csv`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/csv.rg` (dominio `CSV`). Al compilar con `stable bundle`, se empaqueta en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/csv.rglib` | Distribución e importación directa con `import csv` |
| **Archivo compilado** | `target/csv.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libcsv.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import csv` en el encabezado y llamar a sus funciones con espacios o guiones bajos indistintamente.

---

## 3. Referencia rápida de la API de `csv`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `csv parse / tsv parse / csv parse with` | Analiza texto CSV/TSV (incluyendo celdas multilínea y escapes `""`) en `[[String]]` |
| `csv stringify / tsv stringify` | Serializa `[[String]]` entrecomillando solo celdas con delimitadores, comillas o saltos |
| `csv parse table / csv get cell / csv col` | Consulta sobre `CsvTable` indexada por cabecera `(fila, nombre_col)` o columna completa |
| `csv row to kv / csv table to kv list` | Convierte filas tabulares en diccionarios `[String String]` indexados por cabecera |

---

## 4. Recetas prácticas en estilo tabular

### Receta 1: Flujo principal con `csv`

Observa cómo los signos `=` y los pasos de transformación quedan alineados como una tabla limpia:

```ridgun
import csv

fn :: extraer columna precios (raw_csv : String) => ([String], String)
      extraer columna precios raw_csv =
        tabla   = csv parse table raw_csv
        precios = csv col tabla "precio"
        primero = csv get cell tabla 0 "producto" "desconocido"
        (precios, primero)
```

### Receta 2: Composición segura y sin efectos laterales

Toda función de la lib `csv` es componible con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import csv

fn :: exportar informe () => String
      exportar informe =
        filas = [["id", "nota"], ["1", "Contiene, coma"], ["2", "Dijo "hola""]]
        csv stringify filas
```

---

## 5. Bajo el capó: rendimiento, memoria RMM y garantías

- **Garantía algorítmica y de seguridad**: Soporte exacto de saltos `\r\n` y `\n` tanto fuera como dentro de comillas, y cero pérdida de datos en viajes de ida y vuelta `csv parse (csv stringify filas)`.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test_csv.rg`.
