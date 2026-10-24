# Capítulo 02: La lib `math` — Aritmética Segura, Teoría de Números y Estadística

## 1. ¿Por qué existe la lib `math`?

Seamos sinceros: una división por cero inesperada en producción o el operador `%` devolviendo restos negativos en C o Java han tumbado más servicios de los que nos gusta admitir.

La lib **`math`** ofrece divisiones totales a prueba de `d == 0` (`div ceil`, `div floor`, `div euclid`, `mod euclid`), exponenciación e inverso modular en $O(\log E)$, raíces y logaritmos enteros exactos, combinatoria, primalidad y el operador mixfix `clamp x between lo and hi`.

---

## 2. Artefactos, importación y arquitectura sin `libc`

En `ridgun-libs`, **`math`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/math.rg` (dominio `MATH`). Al compilar con `stable bundle`, se empaqueta en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/math.rglib` | Distribución e importación directa con `import math` |
| **Archivo compilado** | `target/math.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libmath.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import math` en el encabezado y llamar a sus funciones con espacios o guiones bajos indistintamente.

---

## 3. Referencia rápida de la API de `math`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `math abs / math sign / math min / math max` | Magnitud absoluta, signo (`-1, 0, 1`) y extremos |
| `clamp x between lo and hi` | Operador mixfix (`op ::`) que acota `x` al rango `[lo, hi]` |
| `math div ceil / math div floor / math div euclid / math mod euclid` | Redondeo seguro ante división por cero y resto euclídeo no negativo |
| `math pow / math isqrt / math ilog2 / math ilog10` | Potencia en $O(\log E)$, raíz cuadrada entera de Newton y logaritmos enteros |
| `math gcd / math lcm / math mod pow / math mod inv / math is prime` | MCD/MCM de Euclides, aritmética modular y test de primalidad $6k \pm 1$ |
| `math sum / math mean floor / math median floor / math variance floor` | Combinatoria (`nCr`) sin desbordamiento y estadística entera sobre listas |

---

## 4. Recetas prácticas en estilo tabular

### Receta 1: Flujo principal con `math`

Observa cómo los signos `=` y los pasos de transformación quedan alineados como una tabla limpia:

```ridgun
import math

fn :: verificar clave modular (base : Int) (primo : Int) => (Int, Int, Bool)
      verificar clave modular base primo =
        es_p = math is prime primo
        pot  = math mod pow base (primo - 1) primo
        inv  = math mod inv base primo
        (pot, inv, es_p)
```

### Receta 2: Composición segura y sin efectos laterales

Toda función de la lib `math` es componible con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import math

fn :: calcular paginas y cuota (items : Int) (por_pag : Int) (uso : Int) => (Int, Int)
      calcular paginas y cuota items por_pag uso =
        pags  = math div ceil items por_pag
        cuota = clamp uso between 0 and 100
        (pags, cuota)
```

---

## 5. Bajo el capó: rendimiento, memoria RMM y garantías

- **Garantía algorítmica y de seguridad**: Funciones totales (devuelven `0` cuando el divisor o módulo es `<= 0` en lugar de abortar con `SIGFPE`), sin coma flotante imprecisa.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test_math.rg`.
