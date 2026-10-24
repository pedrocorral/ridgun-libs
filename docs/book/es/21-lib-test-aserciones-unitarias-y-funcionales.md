# Capítulo 21: La lib `test` — Primitivas de Aserción Unitaria y Funcional (`RG-011`)

## 21.1. ¿Por qué existe la lib `test`? (El problema real y la filosofía Ridgun)

> *«¿Por qué necesito una lib `test` escrita desde cero en Ridgun puro en lugar de enlazar una librería de C de toda la vida?»*

Esa es la primera pregunta que se hace cualquier ingeniero de sistemas al llegar a `test`. Y la respuesta resume toda la filosofía de `ridgun-libs`:

Seamos sinceros: cuando un framework de tests requiere macros mágicas, reflexión en tiempo de ejecución o un runner externo pesado, escribir pruebas deja de ser inmediato.

La lib **`test`** (`RG-011`) proporciona aserciones puras, polimórficas y específicas de tipo que emiten diagnósticos claros `[FAIL]` con los valores esperado y obtenido y terminan con código de salida `1` en cuanto falla una invariante.

En un ecosistema tradicional, resolver las tareas del dominio **`TST`** implica arrastrar dependencias externas en C, lidiar con punteros crudos, conversiones opacas de tipos, excepciones no verificadas o pausas impredecibles del recolector de basura. En Ridgun, la lib **`test`** (`src/main/ridgun/lib/test.rg`) aborda el problema con cuatro principios innegociables:

1. **Funciones totales y contratos explícitos (`=>`)**: ninguna función de `test` lanza excepciones ocultas ni depende de `null`. Todo caso límite (entradas vacías, divisores cero, tramas truncadas o índices fuera de rango) devuelve un valor centinela documentado o un tipo algebraico suma (`Option`, `Result`).
2. **Cero código C y cero `libc`**: todo el código de `test` compila directamente a código máquina nativo ELF64 verificado por `ridgunc`.
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos los recorridos internos de `test` se compilan a bucles nativos en $O(1)$ espacio de pila.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estructura intermedia se libera en el instante exacto en que termina su última lectura, sin *Garbage Collector*.

---

## 21.2. Artefactos nativos, importación y catálogo completo de la API de `test`

En `ridgun-libs`, **`test`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/test.rg` (dominio `TST`). Al compilar con `stable bundle`, se empaqueta en tres artefactos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/test.rglib` | Distribución e importación directa con `import test` |
| **Archivo compilado** | `target/test.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libtest.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import test` en el encabezado y llamar a sus funciones con espacios (`mi funcion x`) o guiones bajos (`mi_funcion x`) indistintamente.

### 21.2.1. Resumen de familias funcionales de `test`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `assert equals / assert eq : A -> A -> String -> ()` | Aserción polimórfica de igualdad con etiqueta descriptiva del caso de prueba |
| `assert int equals / assert str eq` | Aserciones especializadas de igualdad para `Int` y `String` |
| `assert true / assert false / assert not` | Aserciones de invariantes booleanas (`True` / `False`) |
| `assert ok : Int -> String -> ()` | Verifica que un código de estado del sistema o socket sea `0` (`OK`) |

### 21.2.2. Catálogo exhaustivo de tipos y firmas en `src/main/ridgun/lib/test.rg`

A continuación tienes el inventario completo de tipos algebraicos (`type`), operadores (`op ::`) y firmas de funciones (`fn ::`) definidos en `src/main/ridgun/lib/test.rg` (`0` tipos, `0` operadores y `12` funciones):

| # | Función / Firma (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: fail test String` | `()` |
| `2` | `fn :: check eq A A` | `Bool` |
| `3` | `fn :: check str eq String String` | `Bool` |
| `4` | `fn :: check true Bool` | `Bool` |
| `5` | `fn :: assert true Bool String` | `()` |
| `6` | `fn :: assert false Bool String` | `()` |
| `7` | `fn :: assert equals A A String` | `()` |
| `8` | `fn :: assert str eq String String String` | `()` |
| `9` | `fn :: assert int equals Int Int String` | `()` |
| `10` | `fn :: assert ok Bool` | `()` |
| `11` | `fn :: assert not Bool` | `()` |
| `12` | `fn :: assert eq A A` | `()` |

---

## 21.3. Explorando `test` a fondo: Ejemplos paso a paso de cada funcionalidad

No basta con ver la tabla de firmas: vamos a explorar **cada una de las funcionalidades** de la lib `test` mediante ejemplos progresivos y ejecutables en Ridgun. Empezaremos por las dos recetas tabulares de uso cotidiano y después recorreremos en detalle todos los escenarios funcionales, transformaciones y casos límite verificados en `src/test/ridgun/test test.rg`.

### 21.3.1. Ejemplo 1: Flujo principal en estilo tabular con `test`

Observa cómo en Ridgun los signos `=` y los pasos de transformación con `test` quedan alineados como una tabla limpia, sin variables mutables innecesarias ni efectos laterales ocultos:

```ridgun
import test
import math

fn :: suite matematicas () => ()
      suite matematicas =
        _ = assert int equals 12 (math gcd 36 60) "MCD de 36 y 60"
        _ = assert true (math is prime 97) "97 es primo"
        echo "[PASS] suite matematicas"
```

### 21.3.2. Ejemplo 2: Composición segura y manejo de casos de borde

Toda función de la lib `test` está diseñada para componerse con guardas booleanas `|` y con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import test

fn :: verificar codigo sistema (rc : Int) => ()
      verificar codigo sistema rc =
        assert ok rc "operacion de descriptor exitosa"
```

### 21.3.3. Ejemplo 3: Predicados booleanos (`check eq`, `check str eq`, `check true`) y aserciones RG-011 con diagnóstico (`assert equals`, `assert str eq`, `assert int equals`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `test` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test rg011 assertions => ()
      test rg011 assertions =
        _ = assert equals 4 4 "math int equality"
        _ = assert equals "ok" "ok" "string equality"
        _ = assert equals True True "bool equality"
        _ = assert true (1 < 2) "1 < 2 holds"
        _ = assert false (1 > 2) "1 > 2 is false"
        _ = assert str eq "ridgun" "ridgun" "str eq helper"
        _ = assert int equals 42 42 "int eq helper"
        _ = assert eq 10 10
        _ = assert ok True
        _ = assert not False
        _ = assert true (check eq 2 2) "check eq True"
        _ = assert false (check eq 1 2) "check eq False"
        _ = assert true (check str eq "a" "a") "check str eq True"
        _ = assert false (check str eq "a" "b") "check str eq False"
        _ = assert true (check true True) "check true True"
        assert false (check true False) "check true False"
```

### 21.3.4. Ejemplo 4: Composición de suites unitarias y funcionales combinando predicados puros y aserciones concisas (`assert ok`, `assert not`, `assert eq`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `test` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
import test

fn :: validar invariantes de dominio (x : Int) (nombre : String) => Bool
      validar invariantes de dominio x nombre =
        ok_num = check eq (x * 2) (x + x)
        ok_str = check str eq nombre "ridgun"
        check true (ok_num and ok_str)

fn :: ejecutar suite de ejemplo => ()
      ejecutar suite de ejemplo =
        -- 1. Predicados puros sin salida del proceso (`check_*`)
        _ = assert true (validar invariantes de dominio 21 "ridgun") "predicado compuesto"
        -- 2. Aserciones anotadas con mensaje diagnóstico (`assert_*`)
        _ = assert int equals (20 + 22) 42 "suma entera exacta"
        _ = assert str eq "rglib" "rglib" "etiqueta de artefacto"
        -- 3. Aserciones concisas sin etiqueta (`assert ok`, `assert not`, `assert eq`)
        _ = assert ok (10 > 5)
        _ = assert not (10 < 5)
        _ = assert eq [1, 2, 3] [1, 2, 3]
        ()
```

---

## 21.4. Bajo el capó: cómo está construida `test` en Ridgun puro (`src/main/ridgun/lib/test.rg`)

Una de las mayores ventajas de `ridgun-libs` es que **no hay cajas negras en C**. Puedes abrir `src/main/ridgun/lib/test.rg` y leer exactamente cómo está implementada cada operación usando *pattern matching*, árboles de guardas `|` / `|.` y recursión de cola (TCO). Veamos las piezas clave de su implementación real:

### 21.4.1. Implementación interna: Non-Exiting Predicate Helpers

Fíjate en cómo `test.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: check eq A      A        => Bool
      check eq actual expected =  actual == expected

fn :: check str eq String String   => Bool
      check str eq actual expected =  actual == expected

fn :: check true Bool => Bool
      check true cond =  cond
```

### 21.4.2. Implementación interna: RG-011 Message-Annotated Assertions

Fíjate en cómo `test.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: assert true Bool String => ()
      assert true cond label  =
        | cond      = ()
        | otherwise = fail test "assert_true failed: {label}"

fn :: assert false Bool String => ()
      assert false cond label  =
        | not cond  = ()
        | otherwise = fail test "assert_false failed: {label}"

fn :: assert equals A      A        String => ()
      assert equals actual expected label  =
        | actual == expected = ()
        | otherwise          = fail test "assert_equals failed: {label}"

fn :: assert str eq String String String => ()
      assert str eq actual expected label =
        | actual == expected = ()
        | otherwise          = fail test "assert_str_eq failed ({label}): got '{actual}', expected '{expected}'"

fn :: assert int equals Int Int String => ()
      assert int equals actual expected label =
        | actual == expected = ()
        | otherwise          = fail test "assert_int_equals failed ({label}): got {actual}, expected {expected}"
```

### 21.4.3. Implementación interna: Concise Label-Free Assertion Helpers

Fíjate en cómo `test.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: assert ok Bool => ()
      assert ok cond =  assert true cond "assert_ok"

fn :: assert not Bool => ()
      assert not cond =  assert false cond "assert_not"

fn :: assert eq A      A        => ()
      assert eq actual expected =  assert equals actual expected "assert_eq"
```

---

## 21.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` y las 5 Reglas de Oro de `test`

- **Garantía algorítmica y de seguridad**: Las 30 suites de pruebas de `ridgun-libs` (`src/test/ridgun/test_*.rg`, más de 4 000 líneas) se ejecutan con esta misma lib mediante `stable test`.
- **Complejidad de pila $O(1)$ con TCO**: Todos los bucles recursivos en `src/main/ridgun/lib/test.rg` están en posición de cola, por lo que `ridgunc` los compila a saltos nativos sin crecimiento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test test.rg`.

### Las 5 Reglas de Oro al programar con `test`

1. **Declara `import test` al inicio del archivo** y aprovecha la equivalencia entre espacios y guiones bajos para que tu código se lea como prosa.
2. **Alinea tus tuberías de datos con `=`**: encadena las llamadas a `test` en pasos con nombre propio y deja que `stable format` alinee las columnas.
3. **Aprovecha las funciones totales de `test` en tus guardas `|`**: comprueba los valores de retorno o desenvuelve los ADTs con *pattern matching* en lugar de asumir que la entrada externa siempre es válida.
4. **Evita copiar grandes estructuras si solo necesitas consultar un campo**: recuerda que en `RMM2` los argumentos de entrada no incrementan ni decrementan contadores (`+0` / `-0`).
5. **Combina `test` con `test` (`import test`)**: escribe siempre aserciones con `assert equals` o `assert true` para fijar los invariantes de tu dominio.

---

En el **Capítulo 22** pasaremos a explorar en profundidad la lib **`posix`** (La lib `posix` — Capa de Abstracción de Plataforma (PAL), Relojes, Señales y CSPRNG).
