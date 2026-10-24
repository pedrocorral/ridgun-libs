# Capítol 21: La lib `test` — Primitives d'Asserció Unitària i Funcional (`RG-011`)

## 21.1. Per què existeix la lib `test`? (El problema real i la filosofia Ridgun)

> *«Per què necessito una lib `test` escrita des de zero en Ridgun pur en lloc d'enllaçar una llibreria de C de tota la vida?»*

Aquesta és la primera pregunta que es fa qualsevol enginyer de sistemes en arribar a `test`. I la resposta resumeix tota la filosofia de `ridgun-libs`:

Siguem sincers: quan un framework de tests requereix macros màgiques, reflexió en temps d'execució o un runner extern pesat, escriure proves deixa de ser immediat.

La lib **`test`** (`RG-011`) proporciona assercions pures, polimòrfiques i específiques de tipus que emeten diagnòstics clars `[FAIL]` amb els valors esperat i obtingut i acaben amb codi de sortida `1` tan bon punt falla una invariant.

En un ecosistema tradicional, resoldre les tasques del domini **`TST`** implica arrossegar dependències externes en C, lluitar amb punters crus, conversions opaques de tipus, excepcions no verificades o pauses impredictibles del recol·lector de brossa. En Ridgun, la lib **`test`** (`src/main/ridgun/lib/test.rg`) aborda el problema amb quatre principis innegociables:

1. **Funcions totals i contractes explícits (`=>`)**: cap funció de `test` llança excepcions ocultes ni depèn de `null`. Tot cas límit retorna un valor sentinella documentat o un tipus algebraic suma (`Option`, `Result`).
2. **Zero codi C i zero `libc`**: tot el codi de `test` compila directament a codi màquina natiu ELF64 verificat per `ridgunc`.
3. **Recursió de cua amb TCO (*Tail-Call Optimization*)**: tots els recorreguts interns de `test` es compilen a bucles natius en espai de pila $O(1)$.
4. **Memòria determinista (`RMM1` / `RMM2`)**: cada estructura intermèdia s'allibera en l'instant exacte en què acaba la seva última lectura, sense *Garbage Collector*.

---

## 21.2. Artefactes natius, importació i catàleg complet de l'API de `test`

A `ridgun-libs`, **`test`** és una **lib** de primera classe situada a `src/main/ridgun/lib/test.rg` (domini `TST`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/test.rglib` | Distribució i importació directa amb `import test` |
| **Fitxer compilat** | `target/test.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libtest.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Per fer servir aquesta lib en qualsevol fitxer `.rg`, n'hi ha prou de declarar `import test` a la capçalera i cridar les seves funcions amb espais o guions baixos indistintament.

### 21.2.1. Resum de famílies funcionals de `test`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `assert equals / assert eq : A -> A -> String -> ()` | Asserció polimòrfica d'igualtat amb etiqueta descriptiva del cas de prova |
| `assert int equals / assert str eq` | Assercions especialitzades d'igualtat per a `Int` i `String` |
| `assert true / assert false / assert not` | Assercions d'invariants booleanes (`True` / `False`) |
| `assert ok : Int -> String -> ()` | Verifica que un codi d'estat del sistema o socket sigui `0` (`OK`) |

### 21.2.2. Catàleg exhaustiu de tipus i signatures a `src/main/ridgun/lib/test.rg`

A continuació tens l'inventari complet de tipus algebraics (`type`), operadors (`op ::`) i signatures de funcions (`fn ::`) definits a `src/main/ridgun/lib/test.rg` (`0` tipus, `0` operadors i `12` funcions):

| # | Funció / Signatura (`fn ::`) | Tipus de Retorn |
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

## 21.3. Explorant `test` a fons: Exemples pas a pas de cada funcionalitat

No n'hi ha prou de veure la taula de signatures: explorarem **cadascuna de les funcionalitats** de la lib `test` mitjançant exemples progressius i executables en Ridgun. Començarem per les dues receptes tabulars d'ús quotidià i després recorrerem en detall tots els escenaris funcionals, transformacions i casos límit verificats a `src/test/ridgun/test test.rg`.

### 21.3.1. Exemple 1: Flux principal en estil tabular amb `test`

Observa com en Ridgun els signes `=` i els passos de transformació amb `test` queden alineats com una taula neta, sense variables mutables innecessàries ni efectes laterals ocults:

```ridgun
import test
import math

fn :: suite matematicas () => ()
      suite matematicas =
        _ = assert int equals 12 (math gcd 36 60) "MCD de 36 y 60"
        _ = assert true (math is prime 97) "97 es primo"
        echo "[PASS] suite matematicas"
```

### 21.3.2. Exemple 2: Composició segura i gestió de casos de vora

Tota funció de la lib `test` està dissenyada per compondre's amb guardes booleanes `|` i amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import test

fn :: verificar codigo sistema (rc : Int) => ()
      verificar codigo sistema rc =
        assert ok rc "operacion de descriptor exitosa"
```

### 21.3.3. Exemple 3: Predicats booleans (`check eq`, `check str eq`, `check true`) i assercions RG-011 amb diagnòstic (`assert equals`, `assert str eq`, `assert int equals`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `test` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

### 21.3.4. Exemple 4: Composició de suites unitàries i funcionals combinant predicats purs i assercions concises (`assert ok`, `assert not`, `assert eq`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `test` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

## 21.4. Sota el capó: com està construïda `test` en Ridgun pur (`src/main/ridgun/lib/test.rg`)

Un dels majors avantatges de `ridgun-libs` és que **no hi ha caixes negres en C**. Pots obrir `src/main/ridgun/lib/test.rg` i llegir exactament com està implementada cada operació fent servir *pattern matching*, arbres de guardes `|` / `|.` i recursió de cua (TCO). Vegem les peces clau de la seva implementació real:

### 21.4.1. Implementació interna: Non-Exiting Predicate Helpers

Fixa't en com `test.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

```ridgun
fn :: check eq A      A        => Bool
      check eq actual expected =  actual == expected

fn :: check str eq String String   => Bool
      check str eq actual expected =  actual == expected

fn :: check true Bool => Bool
      check true cond =  cond
```

### 21.4.2. Implementació interna: RG-011 Message-Annotated Assertions

Fixa't en com `test.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

### 21.4.3. Implementació interna: Concise Label-Free Assertion Helpers

Fixa't en com `test.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

```ridgun
fn :: assert ok Bool => ()
      assert ok cond =  assert true cond "assert_ok"

fn :: assert not Bool => ()
      assert not cond =  assert false cond "assert_not"

fn :: assert eq A      A        => ()
      assert eq actual expected =  assert equals actual expected "assert_eq"
```

---

## 21.5. Garanties algorísmiques, memòria `RMM1`/`RMM2` i les 5 Regles d'Or de `test`

- **Garantia algorísmica i de seguretat**: Les 30 suites de proves de `ridgun-libs` (`src/test/ridgun/test_*.rg`, més de 4 000 línies) s'executen amb aquesta mateixa lib mitjançant `stable test`.
- **Complexitat de pila $O(1)$ amb TCO**: Tots els bucles recursius a `src/main/ridgun/lib/test.rg` estan en posició de cua, de manera que `ridgunc` els compila a salts natius sense creixement de pila.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test test.rg`.

### Les 5 Regles d'Or en programar amb `test`

1. **Declara `import test` a l'inici del fitxer** i aprofita l'equivalència entre espais i guions baixos perquè el teu codi es llegeixi com a prosa.
2. **Alinea les teves canonades de dades amb `=`**: encadena les crides a `test` en passos amb nom propi i deixa que `stable format` alineï les columnes.
3. **Aprofita les funcions totals de `test` a les teves guardes `|`**: comprova els valors de retorn o desembolica els ADTs amb *pattern matching* en lloc d'assumir que l'entrada externa sempre és vàlida.
4. **Evita copiar grans estructures si només necessites consultar un camp**: recorda que en `RMM2` els arguments d'entrada no incrementen ni decrementen comptadors (`+0` / `-0`).
5. **Combina `test` amb `test` (`import test`)**: escriu sempre assercions amb `assert equals` o `assert true` per fixar els invariants del teu domini.

---

Al **Capítol 22** passarem a explorar en profunditat la lib **`posix`** (La lib `posix` — Capa d'Abstracció de Plataforma (PAL), Rellotges, Senyals i CSPRNG).
