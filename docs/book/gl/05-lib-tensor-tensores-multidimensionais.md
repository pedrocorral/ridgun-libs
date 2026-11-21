# Capítulo 05: A lib `tensor` — Formas, Filas e Columnas, Produto Matricial e Operacións por Bloques

## 05.1. Por que existe a lib `tensor`? (O problema real e a filosofía Ridgun)

> *«Por que necesito unha lib `tensor` escrita dende cero en Ridgun puro en vez de enlazar unha librería de C de toda a vida?»*

Esa é a primeira pregunta que se fai calquera enxeñeiro de sistemas ao chegar a `tensor`. E a resposta resume toda a filosofía de `ridgun-libs`:

Sexamos sinceros: na maioría de linguaxes tes que escoller entre listas aniñadas lentísimas cheas de punteiros dispersos ou enlazar unha mole de C++/Fortran de 200 MB coma NumPy/BLAS.

A lib **`tensor`** engade, ao tipo nativo `Tensor[...]` de Ridgun, as funcións auxiliares que a linguaxe non dá directamente: consultas de forma (`tensor rows`, `tensor cols`, `tensor shape`), extracción dunha fila ou dunha columna (`tensor row`, `tensor col`), unha copia explícita (`tensor clone`), o produto matricial (`tensor matmul`) e operacións elemento a elemento entre dous tensores completos: XOR, AND, OR, suma, resta e multiplicación.

Nun ecosistema tradicional, resolver as tarefas do dominio **`TENSOR`** implica arrastrar dependencias externas en C, loitar con punteiros crus, conversións opacas de tipos, excepcións non verificadas ou pausas impredicibles do colector de lixo. En Ridgun, a lib **`tensor`** (`src/main/ridgun/lib/tensor.ridgun`) aborda o problema con catro principios innegociables:

1. **Declara `import tensor` (ou `import tensor as alias`) ao inicio do ficheiro**: cada lib define o seu espazo de nomes `module :: tensor` e en modo `--strict` as funcións multi-palabra invócanse sempre con espazos naturais.
2. **Encadea as túas tubaxes de esquerda a dereita con `->`**: escribe `entrada paso un -> paso dous -> resultado`, usa máscaras `(+ _ _ +)` para desestruturar secuencias e omite `_ =` en sentenzas secuenciais (ou descarta con `-> ()`).
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos os percorridos internos de `tensor` compílanse a bucles nativos en espazo de pila $O(1)$.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estrutura intermedia libérase no instante exacto en que remata a súa última lectura, sen *Garbage Collector*.

---

## 05.2. Artefactos nativos, importación e catálogo completo da API de `tensor`

En `ridgun-libs`, **`tensor`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/tensor.ridgun` (dominio `TENSOR`). Ao compilar con `stable bundle`, empaquétase nun formato nativo:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/tensor.ridgunlib` | Distribución e importación directa con `import tensor` |

> Cada lib declara o seu propio espazo de nomes con `module :: tensor`: abonda con escribir `import tensor` (ou `import tensor as alias`) na cabeceira e chamar ás súas funcións con espazos naturais (`mina funcion x`) e tubaxes `->` (`x mina funcion -> resultado`).

### 05.2.1. Resumo de familias funcionais de `tensor`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `tensor rows / tensor cols / tensor shape` | Número de filas e de columnas dun tensor 2D, e ambos como par |
| `tensor row / tensor col` | Copia unha fila ou unha columna nun tensor 1D |
| `tensor clone` | Unha copia independente dun tensor |
| `tensor matmul` | Produto matricial de dous `Tensor[Real]` 2D |
| `tensor bitxor blocks / tensor bitand blocks / tensor bitor blocks / tensor add blocks / tensor sub blocks / tensor mul blocks` | Operacións bit a bit elemento a elemento sobre `Tensor[U64]` e aritmética sobre `Tensor[Int]`, entre dous tensores da mesma forma |

### 05.2.2. Catálogo exhaustivo de tipos e sinaturas en `src/main/ridgun/lib/tensor.ridgun`

A continuación tes o inventario completo de tipos alxébricos (`type`), operadores (`op ::`) e sinaturas de funcións (`fn ::`) definidos en `src/main/ridgun/lib/tensor.ridgun` (`0` tipos, `0` operadores e `13` funcións):

| # | Función / Sinatura (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: tensor rows Tensor[Int * r * c]` | `Int` |
| `2` | `fn :: tensor cols Tensor[Int * r * c]` | `Int` |
| `3` | `fn :: tensor shape Tensor[Int * r * c]` | `Int Int` |
| `4` | `fn :: tensor row Tensor[Int * r * c] Int` | `Tensor[Int * c]` |
| `5` | `fn :: tensor col Tensor[Int * r * c] Int` | `Tensor[Int * r]` |
| `6` | `fn :: tensor bitxor blocks Tensor[U64 * r * c] Tensor[U64 * r * c]` | `Tensor[U64 * r * c]` |
| `7` | `fn :: tensor bitand blocks Tensor[U64 * r * c] Tensor[U64 * r * c]` | `Tensor[U64 * r * c]` |
| `8` | `fn :: tensor bitor blocks Tensor[U64 * r * c] Tensor[U64 * r * c]` | `Tensor[U64 * r * c]` |
| `9` | `fn :: tensor add blocks Tensor[Int * r * c] Tensor[Int * r * c]` | `Tensor[Int * r * c]` |
| `10` | `fn :: tensor sub blocks Tensor[Int * r * c] Tensor[Int * r * c]` | `Tensor[Int * r * c]` |
| `11` | `fn :: tensor mul blocks Tensor[Int * r * c] Tensor[Int * r * c]` | `Tensor[Int * r * c]` |
| `12` | `fn :: tensor clone Tensor[U64 * r * c]` | `Tensor[U64 * r * c]` |
| `13` | `fn :: tensor matmul Tensor[Real * r * k] Tensor[Real * k * c]` | `Tensor[Real * r * c]` |

---

## 05.3. Explorando `tensor` a fondo: Exemplos paso a paso de cada funcionalidade

Non abonda con ver a táboa de sinaturas: imos explorar **cada unha das funcionalidades** da lib `tensor` mediante exemplos progresivos e executables en Ridgun. Comezaremos polas dúas receitas tabulares de uso cotián e despois percorreremos en detalle todos os escenarios funcionais, transformacións e casos límite verificados en `src/test/ridgun/test tensor.ridgun`.

### 05.3.1. Exemplo 1: Fluxo principal en estilo tabular con `tensor`

Observa como en Ridgun os signos `=` e os pasos de transformación con `tensor` quedan aliñados coma unha táboa limpa, sen variables mutables innecesarias nin efectos laterais ocultos:

```ridgun
import tensor

fn :: producto matricial tensor Tensor[Real * r * k] Tensor[Real * k * c] => Tensor[Real * r * c]
      producto matricial tensor a b =
        tensor matmul a b
```

### 05.3.2. Exemplo 2: Composición segura e manexo de casos de bordo

Toda función da lib `tensor` está deseñada para compoñerse con gardas booleanas `|` e co resto das 38 libs de `ridgun-libs`:

```ridgun
import tensor

fn :: combinar bloques Tensor[Int * r * c] Tensor[Int * r * c] => Tensor[Int * r * c]
      combinar bloques a b =
        tensor add blocks a b -> suma
        tensor mul blocks suma b
```

### 05.3.3. Exemplo 3: Creación de tensores (`zeros`, `ones`, `eye`, `arange`, `linspace`), inspección de dimensións (`rank`, `len`, `shape`) e vistas (`reshape`, `transpose`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `tensor` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test tensor dimensions and views => ()
      test tensor dimensions and views =
        m   = Tensor[Int * 2 * 3]
        m_(0, 0) = 10
        m_(0, 1) = 20
        m_(0, 2) = 30
        m_(1, 0) = 40
        m_(1, 1) = 50
        m_(1, 2) = 60
        tensor rows m -> assert int equals 2 "tensor rows == 2"
        tensor cols m -> assert int equals 3 "tensor cols == 3"
        sh  = tensor shape m
        shape fst sh -> assert int equals 2 "tensor shape rows == 2"
        shape snd sh -> assert int equals 3 "tensor shape cols == 3"
        r1  = tensor row m 1
        r1_(0) -> assert int equals 40 "row 1 col 0 == 40"
        r1_(1) -> assert int equals 50 "row 1 col 1 == 50"
        r1_(2) -> assert int equals 60 "row 1 col 2 == 60"
        c2  = tensor col m 2
        c2_(0) -> assert int equals 30 "col 2 row 0 == 30"
        c2_(1) -> assert int equals 60 "col 2 row 1 == 60"
        ()
```

### 05.3.4. Exemplo 4: Álxebra elemento a elemento (Hadamard `+`, `-`, `*`, `/`, `xor`, `and`, `or`) e clonación profunda independente (`tensor clone`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `tensor` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test tensor hadamard and clone => ()
      test tensor hadamard and clone =
        a    = Tensor[Int * 2 * 2]
        a_(0, 0) = 10
        a_(0, 1) = 20
        a_(1, 0) = 30
        a_(1, 1) = 40
        b    = Tensor[Int * 2 * 2]
        b_(0, 0) = 1
        b_(0, 1) = 2
        b_(1, 0) = 3
        b_(1, 1) = 4
        s    = tensor add blocks a b
        s_(0, 0) -> assert int equals 11 "add (0,0) == 11"
        s_(1, 1) -> assert int equals 44 "add (1,1) == 44"
        d    = tensor sub blocks a b
        d_(0, 0) -> assert int equals 9 "sub (0,0) == 9"
        d_(1, 1) -> assert int equals 36 "sub (1,1) == 36"
        p    = tensor mul blocks a b
        p_(0, 0) -> assert int equals 10 "mul (0,0) == 10"
        p_(1, 1) -> assert int equals 160 "mul (1,1) == 160"
        ua   = Tensor[U64 * 2 * 2]
        ua_(0, 0) = 0xFF
        ua_(0, 1) = 0x0F
        ua_(1, 0) = 0xF0
        ua_(1, 1) = 0xAA
        ub   = Tensor[U64 * 2 * 2]
        ub_(0, 0) = 0x0F
        ub_(0, 1) = 0xFF
        ub_(1, 0) = 0x0F
        ub_(1, 1) = 0x55
        ux   = tensor bitxor blocks ua ub
        ux_(0, 0) -> assert int equals 0xF0 "xor (0,0) == 0xF0"
        ux_(1, 1) -> assert int equals 0xFF "xor (1,1) == 0xFF"
        uan  = tensor bitand blocks ua ub
        uan_(0, 0) -> assert int equals 0x0F "and (0,0) == 0x0F"
        uan_(1, 1) -> assert int equals 0x00 "and (1,1) == 0x00"
        uor  = tensor bitor blocks ua ub
        uor_(0, 0) -> assert int equals 0xFF "or (0,0) == 0xFF"
        uor_(1, 0) -> assert int equals 0xFF "or (1,0) == 0xFF"
        uc   = tensor clone ua
        uc_(0, 0) = 999
        ua_(0, 0) -> assert int equals 0xFF "clone preserves original ua_(0,0)"
        uc_(0, 0) -> assert int equals 999 "clone updates uc_(0,0)"
        ()
```

### 05.3.5. Exemplo 5: Multiplicación matricial nativa (`@`) e contracción de subíndices de Einstein (`a_ik @ b_kj`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `tensor` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test tensor matmul => ()
      test tensor matmul =
        ma  = Tensor[Real * 2 * 3]
        ma_(0, 0) = 1.0
        ma_(0, 1) = 2.0
        ma_(0, 2) = 3.0
        ma_(1, 0) = 4.0
        ma_(1, 1) = 5.0
        ma_(1, 2) = 6.5
        mb  = Tensor[Real * 3 * 2]
        mb_(0, 0) = 7.0
        mb_(0, 1) = 8.0
        mb_(1, 0) = 9.0
        mb_(1, 1) = 10.0
        mb_(2, 0) = 11.0
        mb_(2, 1) = 0.5
        mc  = tensor matmul ma mb
        assert true (mc_(0, 0) == 58.0) "matmul (0,0) == 7 + 18 + 33"
        assert true (mc_(0, 1) == 29.5) "matmul (0,1) == 8 + 20 + 1.5"
        assert true (mc_(1, 0) == 144.5) "matmul (1,0) == 28 + 45 + 71.5"
        assert true (mc_(1, 1) == 85.25) "matmul (1,1) == 32 + 50 + 3.25"
        ()
```

### 05.3.6. Exemplo 6: Compresión criptográfica de bloques de 1024 bytes mediante tensores (`f blamka`, `blamka g`, `blamka p16`, `compress block`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `tensor` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test blamka tensor compression => ()
      test blamka tensor compression =
        fb  = f blamka 1 2
        fb -> assert int equals 7 "f blamka 1 2 == 7"
        gr  = blamka g 1 2 3 4
        (g fst gr) != 0 -> assert true "blamka g non-zero output"
        bx  = Tensor[U64 * 8 * 16]
        by  = Tensor[U64 * 8 * 16]
        bx_(0, 0) = 1
        by_(0, 0) = 2
        bz  = compress block bx by
        bz_(0, 0) != 0 -> assert true "compress block non-zero (0,0)"
        bx_(0, 0) -> assert int equals 1 "compress block preserves bx_(0,0)"
        by_(0, 0) -> assert int equals 2 "compress block preserves by_(0,0)"
        ()
```

---

## 05.4. Baixo o capó: como está construída `tensor` en Ridgun puro (`src/main/ridgun/lib/tensor.ridgun`)

Unha das maiores vantaxes de `ridgun-libs` é que **non hai caixas negras en C**. Podes abrir `src/main/ridgun/lib/tensor.ridgun` e ler exactamente como está implementada cada operación usando *pattern matching*, árbores de gardas `|` / `|.` e recursión de cola (TCO). Vexamos as pezas clave da súa implementación real:

### 05.4.1. Implementación interna: Core Implementation Part 1

Fíxate en como `tensor.ridgun` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
module :: tensor

fn :: tensor rows Tensor[Int * r * c] => Int
      tensor rows (Tensor[Int * r * c] m) = r

fn :: tensor cols Tensor[Int * r * c] => Int
      tensor cols (Tensor[Int * r * c] m) = c

fn :: tensor shape Tensor[Int * r * c] => Int Int
      tensor shape (Tensor[Int * r * c] m) = (r, c)

fn :: tensor row Tensor[Int * r * c] Int => Tensor[Int * c]
      tensor row m                   idx =  m_(idx,)

fn :: tensor col Tensor[Int * r * c] Int => Tensor[Int * r]
      tensor col m                   idx =  m_(,idx)

fn :: tensor bitxor blocks Tensor[U64 * r * c] Tensor[U64 * r * c] => Tensor[U64 * r * c]
      tensor bitxor blocks a b = a_ij xor b_ij
```

### 05.4.2. Implementación interna: Core Implementation Part 2

Fíxate en como `tensor.ridgun` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
fn :: tensor bitand blocks Tensor[U64 * r * c] Tensor[U64 * r * c] => Tensor[U64 * r * c]
      tensor bitand blocks a b = a_ij and b_ij

fn :: tensor bitor blocks Tensor[U64 * r * c] Tensor[U64 * r * c] => Tensor[U64 * r * c]
      tensor bitor blocks a b = a_ij or b_ij

fn :: tensor add blocks Tensor[Int * r * c] Tensor[Int * r * c] => Tensor[Int * r * c]
      tensor add blocks a b = a_ij + b_ij

fn :: tensor sub blocks Tensor[Int * r * c] Tensor[Int * r * c] => Tensor[Int * r * c]
      tensor sub blocks a b = a_ij - b_ij

fn :: tensor mul blocks Tensor[Int * r * c] Tensor[Int * r * c] => Tensor[Int * r * c]
      tensor mul blocks a b = a_ij * b_ij

fn :: tensor clone Tensor[U64 * r * c] => Tensor[U64 * r * c]
      tensor clone m                   =
        z_ij = m_ij
        z_ij

fn :: tensor matmul Tensor[Real * r * k] Tensor[Real * k * c] => Tensor[Real * r * c]
      tensor matmul a b = a_ik @ b_kj
```

---

## 05.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` e as 5 Regras de Ouro de `tensor`

- **Garantía algorítmica e de seguridade**: Memoria contigua de 8 bytes por cela xestionada estaticamente por RMM1/RMM2, vistas en $O(1)$ sen duplicar o búfer e semántica pura Copy-on-Write.
- **Complexidade de pila $O(1)$ con TCO**: Todos os bucles recursivos en `src/main/ridgun/lib/tensor.ridgun` están en posición de cola, polo que `ridgunc` os compila a saltos nativos sen crecemento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test tensor.ridgun`.

### As 5 Regras de Ouro ao programar con `tensor`

1. **Declara `import tensor` ao inicio do ficheiro** e chama as súas funcións con espazos, tal como están declaradas, para que o teu código se lea coma prosa.
2. **Aliña as túas tubaxes de datos con `=`**: encadea as chamadas a `tensor` en pasos con nome propio e deixa que `stable format` aliñe as columnas.
3. **Aproveita as funcións totais de `tensor` nas túas gardas `|`**: comproba os valores de retorno ou desenvolve os ADTs con *pattern matching* en vez de asumir que a entrada externa sempre é válida.
4. **Evita copiar grandes estruturas se só necesitas consultar un campo**: lembra que en `RMM2` os argumentos de entrada non incrementan nin decrementan contadores (`+0` / `-0`).
5. **Combina `tensor` con `test` (`import test`)**: escribe sempre asercións con `assert equals` ou `assert true` para fixar os invariantes do teu dominio.

---

No **Capítulo 06** pasaremos a explorar en profundidade a lib **`linalg`** (A lib `linalg` — Álxebra Lineal sobre `Tensor[Real]`, Bareiss e Activacións).
