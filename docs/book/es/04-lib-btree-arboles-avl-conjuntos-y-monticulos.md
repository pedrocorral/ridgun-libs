# Capítulo 04: La lib `btree` — Árboles AVL Persistentes $O(\log N)$, Conjuntos y Montículos

## 1. ¿Por qué existe la lib `btree`?

Seamos sinceros: las tablas hash mutables sufren ataques de colisión de claves (HashDoS), no mantienen las claves ordenadas para consultas por rango y no pueden compartirse entre actores sin copiarlas enteras o meter un candado.

La lib **`btree`** implementa tres estructuras de datos funcionales persistentes en $O(\log N)$ con compartición estructural: **`BTreeMap`** (árbol AVL auto-balanceado), **`BTreeSet`** (álgebra de conjuntos ordenada) y **`MinHeap`** (cola de prioridad *leftist heap*).

---

## 2. Artefactos, importación y arquitectura sin `libc`

En `ridgun-libs`, **`btree`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/btree.rg` (dominio `BTREE`). Al compilar con `stable bundle`, se empaqueta en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/btree.rglib` | Distribución e importación directa con `import btree` |
| **Archivo compilado** | `target/btree.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libbtree.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import btree` en el encabezado y llamar a sus funciones con espacios o guiones bajos indistintamente.

---

## 3. Referencia rápida de la API de `btree`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `btree empty / btree insert / btree get / btree remove` | Búsqueda, inserción y borrado persistente en diccionario AVL en $O(\log N)$ |
| `btree min key / btree max key / btree range` | Extremos ordenados y consulta por rango `[lo, hi]` |
| `bset from list / bset union / bset intersect / bset diff` | Álgebra de conjuntos ordenados (`BTreeSet`) y predicado de subconjunto |
| `heap empty / heap push / heap peek / heap pop / heap sort` | Cola de prioridad `MinHeap` (*leftist heap*) con fusión en $O(\log N)$ |

---

## 4. Recetas prácticas en estilo tabular

### Receta 1: Flujo principal con `btree`

Observa cómo los signos `=` y los pasos de transformación quedan alineados como una tabla limpia:

```ridgun
import btree

fn :: consultar rango precios () => [String String]
      consultar rango precios =
        t0 = btree empty
        t1 = btree insert t0 "item:10" "Teclado"
        t2 = btree insert t1 "item:20" "Monitor"
        t3 = btree insert t2 "item:30" "Raton"
        btree range t3 "item:10" "item:25"
```

### Receta 2: Composición segura y sin efectos laterales

Toda función de la lib `btree` es componible con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import btree

fn :: despachar urgente () => (Int, String)
      despachar urgente =
        h0 = heap empty
        h1 = heap push h0 50 "backup-nocturno"
        h2 = heap push h1 10 "alerta-seguridad"
        h3 = heap push h2 30 "rotar-logs"
        heap peek h3
```

---

## 5. Bajo el capó: rendimiento, memoria RMM y garantías

- **Garantía algorítmica y de seguridad**: Rotaciones AVL estrictas (`height diff <= 1`), inmunidad total a HashDoS, consultas por rango en $O(\log N + K)$ y fusión de montículos en $O(\log N)$.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test_btree.rg`.
