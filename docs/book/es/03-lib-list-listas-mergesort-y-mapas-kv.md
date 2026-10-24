# Capítulo 03: La lib `list` — Listas, Mergesort $O(N \log N)$ y Mapas Clave-Valor

## 1. ¿Por qué existe la lib `list`?

Seamos sinceros: acceder a un índice fuera de rango (`IndexError` / `panic!`) o mutar una lista compartida por accidente son dos de los errores más frecuentes al procesar colecciones.

La lib **`list`** proporciona indexación con valor por defecto, rebanado (`take`, `drop`, `slice`), rangos con paso, deduplicación estable, ordenación **mergesort $O(N \log N)$** para `[Int]` y `[String]`, y diccionarios asociativos inmutables `[String String]` (`kv get`, `kv put`, `kv merge`).

---

## 2. Artefactos, importación y arquitectura sin `libc`

En `ridgun-libs`, **`list`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/list.rg` (dominio `LIST`). Al compilar con `stable bundle`, se empaqueta en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/list.rglib` | Distribución e importación directa con `import list` |
| **Archivo compilado** | `target/list.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/liblist.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import list` en el encabezado y llamar a sus funciones con espacios o guiones bajos indistintamente.

---

## 3. Referencia rápida de la API de `list`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `list nth or / list str nth or` | Lectura segura por índice devolviendo `default_val` si está fuera de rango |
| `list take / list drop / list slice / list reverse` | Prefijo, sufijo, subrango `[start, end)` e inversión recursiva de cola |
| `list range / list range step` | Genera secuencias aritméticas (`step == 0` devuelve `[]` de forma segura) |
| `list sort / list str sort / list dedup / list str dedup` | Ordenación mergesort $O(N \log N)$ estable y deduplicación por primera aparición |
| `kv empty / kv put / kv get / kv get or / kv remove / kv merge` | Operaciones sobre diccionarios asociativos ordenados `[String String]` |

---

## 4. Recetas prácticas en estilo tabular

### Receta 1: Flujo principal con `list`

Observa cómo los signos `=` y los pasos de transformación quedan alineados como una tabla limpia:

```ridgun
import list

fn :: top tres unicos (puntos : [Int]) => [Int]
      top tres unicos puntos =
        unicos    = list dedup puntos
        ordenados = list reverse (list sort unicos)
        list take ordenados 3
```

### Receta 2: Composición segura y sin efectos laterales

Toda función de la lib `list` es componible con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import list

fn :: configurar entorno (base : [String String]) => (String, [String])
      configurar entorno base =
        cfg1 = kv put base "host" "0.0.0.0"
        cfg2 = kv put cfg1 "port" "8080"
        host = kv get or cfg2 "host" "127.0.0.1"
        (host, kv keys cfg2)
```

---

## 5. Bajo el capó: rendimiento, memoria RMM y garantías

- **Garantía algorítmica y de seguridad**: Ordenación determinista $O(N \log N)$ en el peor caso (sin el $O(N^2)$ patológico de Quicksort) y preservación del orden de inserción en mapas `kv`.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test_list.rg`.
