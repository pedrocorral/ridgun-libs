# Capítulo 02: A lib `math` — Aritmética Segura, Teoría de Números e Estatística

## 1. Por que existe a lib `math`?

Sexamos sinceros: unha división por cero inesperada en produción ou o operador `%` devolvendo restos negativos en C ou Java teñen tombado máis servizos dos que nos gusta admitir.

A lib **`math`** ofrece divisións totais a proba de `d == 0` (`div ceil`, `div floor`, `div euclid`, `mod euclid`), exponenciación e inverso modular en $O(\log E)$, raíces e logaritmos enteiros exactos, combinatoria, primalidade e o operador mixfix `clamp x between lo and hi`.

---

## 2. Artefactos, importación e arquitectura sen `libc`

En `ridgun-libs`, **`math`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/math.rg` (dominio `MATH`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/math.rglib` | Distribución e importación directa con `import math` |
| **Ficheiro compilado** | `target/math.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libmath.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import math` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

---

## 3. Referencia rápida da API de `math`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `math abs / math sign / math min / math max` | Magnitude absoluta, signo (`-1, 0, 1`) e extremos |
| `clamp x between lo and hi` | Operador mixfix (`op ::`) que acouta `x` ao rango `[lo, hi]` |
| `math div ceil / math div floor / math div euclid / math mod euclid` | Redondeo seguro ante división por cero e resto euclidiano non negativo |
| `math pow / math isqrt / math ilog2 / math ilog10` | Potencia en $O(\log E)$, raíz cadrada enteira de Newton e logaritmos enteiros |
| `math gcd / math lcm / math mod pow / math mod inv / math is prime` | MCD/MCM de Euclides, aritmética modular e test de primalidade $6k \pm 1$ |
| `math sum / math mean floor / math median floor / math variance floor` | Combinatoria (`nCr`) sen desbordamento e estatística enteira sobre listas |

---

## 4. Receitas prácticas en estilo tabular

### Receita 1: Fluxo principal con `math`

Observa como os signos `=` e os pasos de transformación quedan aliñados coma unha táboa limpa:

```ridgun
import math

fn :: verificar clave modular (base : Int) (primo : Int) => (Int, Int, Bool)
      verificar clave modular base primo =
        es_p = math is prime primo
        pot  = math mod pow base (primo - 1) primo
        inv  = math mod inv base primo
        (pot, inv, es_p)
```

### Receita 2: Composición segura e sen efectos laterais

Toda función da lib `math` é compoñible co resto das 32 libs de `ridgun-libs`:

```ridgun
import math

fn :: calcular paginas y cuota (items : Int) (por_pag : Int) (uso : Int) => (Int, Int)
      calcular paginas y cuota items por_pag uso =
        pags  = math div ceil items por_pag
        cuota = clamp uso between 0 and 100
        (pags, cuota)
```

---

## 5. Baixo o capó: rendemento, memoria RMM e garantías

- **Garantía algorítmica e de seguridade**: Funcións totais (devolven `0` cando o divisor ou módulo é `<= 0` en vez de abortar con `SIGFPE`), sen coma flotante imprecisa.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test_math.rg`.
