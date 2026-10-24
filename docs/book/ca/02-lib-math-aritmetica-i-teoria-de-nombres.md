# Capítol 02: La lib `math` — Aritmètica Segura, Teoria de Nombres i Estadística

## 1. Per què existeix la lib `math`?

Siguem sincers: una divisió per zero inesperada a producció o l'operador `%` retornant residus negatius en C o Java han tombat més serveis dels que ens agrada admetre.

La lib **`math`** ofereix divisions totals a prova de `d == 0` (`div ceil`, `div floor`, `div euclid`, `mod euclid`), exponenciació i invers modular en $O(\log E)$, arrels i logaritmes enters exactes, combinatòria, primalitat i l'operador mixfix `clamp x between lo and hi`.

---

## 2. Artefactes, importació i arquitectura sense `libc`

A `ridgun-libs`, **`math`** és una **lib** de primera classe situada a `src/main/ridgun/lib/math.rg` (domini `MATH`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/math.rglib` | Distribució i importació directa amb `import math` |
| **Fitxer compilat** | `target/math.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libmath.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Per fer servir aquesta lib en qualsevol fitxer `.rg`, n'hi ha prou de declarar `import math` a la capçalera i cridar les seves funcions amb espais o guions baixos indistintament.

---

## 3. Referència ràpida de l'API de `math`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `math abs / math sign / math min / math max` | Magnitud absoluta, signe (`-1, 0, 1`) i extrems |
| `clamp x between lo and hi` | Operador mixfix (`op ::`) que acota `x` al rang `[lo, hi]` |
| `math div ceil / math div floor / math div euclid / math mod euclid` | Arrodoniment segur davant divisió per zero i residu euclidià no negatiu |
| `math pow / math isqrt / math ilog2 / math ilog10` | Potència en $O(\log E)$, arrel quadrada entera de Newton i logaritmes enters |
| `math gcd / math lcm / math mod pow / math mod inv / math is prime` | MCD/MCM d'Euclides, aritmètica modular i test de primalitat $6k \pm 1$ |
| `math sum / math mean floor / math median floor / math variance floor` | Combinatòria (`nCr`) sense desbordament i estadística entera sobre llistes |

---

## 4. Receptes pràctiques en estil tabular

### Recepta 1: Flux principal amb `math`

Observa com els signes `=` i els passos de transformació queden alineats com una taula neta:

```ridgun
import math

fn :: verificar clave modular (base : Int) (primo : Int) => (Int, Int, Bool)
      verificar clave modular base primo =
        es_p = math is prime primo
        pot  = math mod pow base (primo - 1) primo
        inv  = math mod inv base primo
        (pot, inv, es_p)
```

### Recepta 2: Composició segura i sense efectes laterals

Tota funció de la lib `math` és componible amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import math

fn :: calcular paginas y cuota (items : Int) (por_pag : Int) (uso : Int) => (Int, Int)
      calcular paginas y cuota items por_pag uso =
        pags  = math div ceil items por_pag
        cuota = clamp uso between 0 and 100
        (pags, cuota)
```

---

## 5. Sota el capó: rendiment, memòria RMM i garanties

- **Garantia algorísmica i de seguretat**: Funcions totals (retornen `0` quan el divisor o mòdul és `<= 0` en lloc d'avortar amb `SIGFPE`), sense coma flotant imprecisa.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test_math.rg`.
