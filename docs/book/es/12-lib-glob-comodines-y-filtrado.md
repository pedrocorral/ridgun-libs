# Capítulo 12: La lib `glob` — Patrones de Comodines (`*`, `?`, `[a-z]`) y Filtrado de Listas

## 1. ¿Por qué existe la lib `glob`?

Seamos sinceros: usar una expresión regular completa solo para comprobar si un archivo termina en `*.rg` o empieza por `test_[0-9]*.rg` es matar moscas a cañonazos.

La lib **`glob`** implementa coincidencia exacta de comodines de shell (`*`, `?`, clases `[a-z]`, clases negadas `[!0-9]` / `[^a-z]`), variantes insensibles a mayúsculas (`glob match ci`) y filtrado directo de listas de rutas o nombres.

---

## 2. Artefactos, importación y arquitectura sin `libc`

En `ridgun-libs`, **`glob`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/glob.rg` (dominio `GLOB`). Al compilar con `stable bundle`, se empaqueta en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/glob.rglib` | Distribución e importación directa con `import glob` |
| **Archivo compilado** | `target/glob.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libglob.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import glob` en el encabezado y llamar a sus funciones con espacios o guiones bajos indistintamente.

---

## 3. Referencia rápida de la API de `glob`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `glob match / glob match ci` | Coincidencia de patrones glob sensible e insensible a mayúsculas ASCII |
| `glob filter / glob any match` | Filtra `[String]` según un patrón o comprueba si coincide algún patrón de una lista |
| `glob has magic` | Detecta si una cadena contiene metacaracteres de comodín (`*`, `?`, `[`) |

---

## 4. Recetas prácticas en estilo tabular

### Receta 1: Flujo principal con `glob`

Observa cómo los signos `=` y los pasos de transformación quedan alineados como una tabla limpia:

```ridgun
import glob

fn :: seleccionar fuentes ridgun (archivos : [String]) => [String]
      seleccionar fuentes ridgun archivos =
        glob filter "test_[a-z]*.rg" archivos
```

### Receta 2: Composición segura y sin efectos laterales

Toda función de la lib `glob` es componible con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import glob

fn :: es ruta excluida (ruta : String) => Bool
      es ruta excluida ruta =
        glob any match ["*.tmp", "*.bak", "target/*"] ruta
```

---

## 5. Bajo el capó: rendimiento, memoria RMM y garantías

- **Garantía algorítmica y de seguridad**: Colapso automático de estrellas consecutivas (`***` $\rightarrow$ `*`) para evitar retrocesos redundantes y manejo seguro de corchetes sin cerrar `[`.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test_glob.rg`.
