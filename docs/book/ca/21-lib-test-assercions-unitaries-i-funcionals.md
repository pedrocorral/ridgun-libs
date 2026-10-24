# Capítol 21: La lib `test` — Primitives d'Asserció Unitària i Funcional (`RG-011`)

## 1. Per què existeix la lib `test`?

Siguem sincers: quan un framework de tests requereix macros màgiques, reflexió en temps d'execució o un runner extern pesat, escriure proves deixa de ser immediat.

La lib **`test`** (`RG-011`) proporciona assercions pures, polimòrfiques i específiques de tipus que emeten diagnòstics clars `[FAIL]` amb els valors esperat i obtingut i acaben amb codi de sortida `1` tan bon punt falla una invariant.

---

## 2. Artefactes, importació i arquitectura sense `libc`

A `ridgun-libs`, **`test`** és una **lib** de primera classe situada a `src/main/ridgun/lib/test.rg` (domini `TST`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/test.rglib` | Distribució i importació directa amb `import test` |
| **Fitxer compilat** | `target/test.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libtest.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Per fer servir aquesta lib en qualsevol fitxer `.rg`, n'hi ha prou de declarar `import test` a la capçalera i cridar les seves funcions amb espais o guions baixos indistintament.

---

## 3. Referència ràpida de l'API de `test`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `assert equals / assert eq : A -> A -> String -> ()` | Asserció polimòrfica d'igualtat amb etiqueta descriptiva del cas de prova |
| `assert int equals / assert str eq` | Assercions especialitzades d'igualtat per a `Int` i `String` |
| `assert true / assert false / assert not` | Assercions d'invariants booleanes (`True` / `False`) |
| `assert ok : Int -> String -> ()` | Verifica que un codi d'estat del sistema o socket sigui `0` (`OK`) |

---

## 4. Receptes pràctiques en estil tabular

### Recepta 1: Flux principal amb `test`

Observa com els signes `=` i els passos de transformació queden alineats com una taula neta:

```ridgun
import test
import math

fn :: suite matematicas () => ()
      suite matematicas =
        _ = assert int equals 12 (math gcd 36 60) "MCD de 36 y 60"
        _ = assert true (math is prime 97) "97 es primo"
        echo "[PASS] suite matematicas"
```

### Recepta 2: Composició segura i sense efectes laterals

Tota funció de la lib `test` és componible amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import test

fn :: verificar codigo sistema (rc : Int) => ()
      verificar codigo sistema rc =
        assert ok rc "operacion de descriptor exitosa"
```

---

## 5. Sota el capó: rendiment, memòria RMM i garanties

- **Garantia algorísmica i de seguretat**: Les 30 suites de proves de `ridgun-libs` (`src/test/ridgun/test_*.rg`, més de 4 000 línies) s'executen amb aquesta mateixa lib mitjançant `stable test`.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test_test.rg`.
