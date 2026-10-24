# Capítulo 21: A lib `test` — Primitivas de Aserción Unitaria e Funcional (`RG-011`)

## 21.1. Por que existe a lib `test`? (O problema real e a filosofía Ridgun)

> *«Por que necesito unha lib `test` escrita dende cero en Ridgun puro en vez de enlazar unha librería de C de toda a vida?»*

Esa é a primeira pregunta que se fai calquera enxeñeiro de sistemas ao chegar a `test`. E a resposta resume toda a filosofía de `ridgun-libs`:

Sexamos sinceros: cando un framework de tests require macros máxicas, reflexión en tempo de execución ou un runner externo pesado, escribir probas deixa de ser inmediato.

A lib **`test`** (`RG-011`) proporciona asercións puras, polimórficas e específicas de tipo que emiten diagnósticos claros `[FAIL]` cos valores esperado e obtido e rematan con código de saída `1` en canto falla unha invariante.

Nun ecosistema tradicional, resolver as tarefas do dominio **`TST`** implica arrastrar dependencias externas en C, loitar con punteiros crus, conversións opacas de tipos, excepcións non verificadas ou pausas impredicibles do colector de lixo. En Ridgun, a lib **`test`** (`src/main/ridgun/lib/test.rg`) aborda o problema con catro principios innegociables:

1. **Funcións totais e contratos explícitos (`=>`)**: ningunha función de `test` lanza excepcións ocultas nin depende de `null`. Todo caso límite devolve un valor sentinela documentado ou un tipo alxébrico suma (`Option`, `Result`).
2. **Cero código C e cero `libc`**: todo o código de `test` compila directamente a código máquina nativo ELF64 verificado por `ridgunc`.
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos os percorridos internos de `test` compílanse a bucles nativos en espazo de pila $O(1)$.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estrutura intermedia libérase no instante exacto en que remata a súa última lectura, sen *Garbage Collector*.

---

## 21.2. Artefactos nativos, importación e catálogo completo da API de `test`

En `ridgun-libs`, **`test`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/test.rg` (dominio `TST`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/test.rglib` | Distribución e importación directa con `import test` |
| **Ficheiro compilado** | `target/test.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libtest.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import test` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

### 21.2.1. Resumo de familias funcionais de `test`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `assert equals / assert eq : A -> A -> String -> ()` | Aserción polimórfica de igualdade con etiqueta descritiva do caso de proba |
| `assert int equals / assert str eq` | Asercións especializadas de igualdade para `Int` e `String` |
| `assert true / assert false / assert not` | Asercións de invariantes booleanas (`True` / `False`) |
| `assert ok : Int -> String -> ()` | Verifica que un código de estado do sistema ou socket sexa `0` (`OK`) |

### 21.2.2. Catálogo exhaustivo de tipos e sinaturas en `src/main/ridgun/lib/test.rg`

A continuación tes o inventario completo de tipos alxébricos (`type`), operadores (`op ::`) e sinaturas de funcións (`fn ::`) definidos en `src/main/ridgun/lib/test.rg` (`0` tipos, `0` operadores e `12` funcións):

| # | Función / Sinatura (`fn ::`) | Tipo de Retorno |
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

## 21.3. Explorando `test` a fondo: Exemplos paso a paso de cada funcionalidade

Non abonda con ver a táboa de sinaturas: imos explorar **cada unha das funcionalidades** da lib `test` mediante exemplos progresivos e executables en Ridgun. Comezaremos polas dúas receitas tabulares de uso cotián e despois percorreremos en detalle todos os escenarios funcionais, transformacións e casos límite verificados en `src/test/ridgun/test test.rg`.

### 21.3.1. Exemplo 1: Fluxo principal en estilo tabular con `test`

Observa como en Ridgun os signos `=` e os pasos de transformación con `test` quedan aliñados coma unha táboa limpa, sen variables mutables innecesarias nin efectos laterais ocultos:

```ridgun
import test
import math

fn :: suite matematicas () => ()
      suite matematicas =
        _ = assert int equals 12 (math gcd 36 60) "MCD de 36 y 60"
        _ = assert true (math is prime 97) "97 es primo"
        echo "[PASS] suite matematicas"
```

### 21.3.2. Exemplo 2: Composición segura e manexo de casos de bordo

Toda función da lib `test` está deseñada para compoñerse con gardas booleanas `|` e co resto das 32 libs de `ridgun-libs`:

```ridgun
import test

fn :: verificar codigo sistema (rc : Int) => ()
      verificar codigo sistema rc =
        assert ok rc "operacion de descriptor exitosa"
```

### 21.3.3. Exemplo 3: Predicados booleanos (`check eq`, `check str eq`, `check true`) e asercións RG-011 con diagnóstico (`assert equals`, `assert str eq`, `assert int equals`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `test` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

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

### 21.3.4. Exemplo 4: Composición de suites unitarias e funcionais combinando predicados puros e asercións concisas (`assert ok`, `assert not`, `assert eq`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `test` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

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

## 21.4. Baixo o capó: como está construída `test` en Ridgun puro (`src/main/ridgun/lib/test.rg`)

Unha das maiores vantaxes de `ridgun-libs` é que **non hai caixas negras en C**. Podes abrir `src/main/ridgun/lib/test.rg` e ler exactamente como está implementada cada operación usando *pattern matching*, árbores de gardas `|` / `|.` e recursión de cola (TCO). Vexamos as pezas clave da súa implementación real:

### 21.4.1. Implementación interna: Non-Exiting Predicate Helpers

Fíxate en como `test.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
fn :: check eq A      A        => Bool
      check eq actual expected =  actual == expected

fn :: check str eq String String   => Bool
      check str eq actual expected =  actual == expected

fn :: check true Bool => Bool
      check true cond =  cond
```

### 21.4.2. Implementación interna: RG-011 Message-Annotated Assertions

Fíxate en como `test.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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

Fíxate en como `test.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
fn :: assert ok Bool => ()
      assert ok cond =  assert true cond "assert_ok"

fn :: assert not Bool => ()
      assert not cond =  assert false cond "assert_not"

fn :: assert eq A      A        => ()
      assert eq actual expected =  assert equals actual expected "assert_eq"
```

---

## 21.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` e as 5 Regras de Ouro de `test`

- **Garantía algorítmica e de seguridade**: As 30 suites de probas de `ridgun-libs` (`src/test/ridgun/test_*.rg`, máis de 4 000 liñas) execútanse con esta mesma lib mediante `stable test`.
- **Complexidade de pila $O(1)$ con TCO**: Todos os bucles recursivos en `src/main/ridgun/lib/test.rg` están en posición de cola, polo que `ridgunc` os compila a saltos nativos sen crecemento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test test.rg`.

### As 5 Regras de Ouro ao programar con `test`

1. **Declara `import test` ao inicio do ficheiro** e aproveita a equivalencia entre espazos e guións baixos para que o teu código se lea coma prosa.
2. **Aliña as túas tubaxes de datos con `=`**: encadea as chamadas a `test` en pasos con nome propio e deixa que `stable format` aliñe as columnas.
3. **Aproveita as funcións totais de `test` nas túas gardas `|`**: comproba os valores de retorno ou desenvolve os ADTs con *pattern matching* en vez de asumir que a entrada externa sempre é válida.
4. **Evita copiar grandes estruturas se só necesitas consultar un campo**: lembra que en `RMM2` os argumentos de entrada non incrementan nin decrementan contadores (`+0` / `-0`).
5. **Combina `test` con `test` (`import test`)**: escribe sempre asercións con `assert equals` ou `assert true` para fixar os invariantes do teu dominio.

---

No **Capítulo 22** pasaremos a explorar en profundidade a lib **`posix`** (A lib `posix` — Capa de Abstracción de Plataforma (PAL), Reloxos, Sinais e CSPRNG).
