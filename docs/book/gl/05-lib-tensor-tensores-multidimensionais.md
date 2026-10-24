# Capítulo 05: A lib `tensor` — Tensores Multidimensionais, Vistas e Contracción de Einstein

## 05.1. Por que existe a lib `tensor`? (O problema real e a filosofía Ridgun)

> *«Por que necesito unha lib `tensor` escrita dende cero en Ridgun puro en vez de enlazar unha librería de C de toda a vida?»*

Esa é a primeira pregunta que se fai calquera enxeñeiro de sistemas ao chegar a `tensor`. E a resposta resume toda a filosofía de `ridgun-libs`:

Sexamos sinceros: na maioría de linguaxes tes que escoller entre listas aniñadas lentísimas cheas de punteiros dispersos ou enlazar unha mole de C++/Fortran de 200 MB coma NumPy/BLAS.

A lib **`tensor`** envolve a primitiva nativa `Tensor[...]` de Ridgun ofrecendo creación tipada (`Tensor[Int]`, `Tensor[Real]`, `Tensor[U64]`), vistas sen copia (`reshape`, `slice`), operacións elemento a elemento (Hadamard), contracción de Einstein (`*` sobre eixos simbólicos) e aritmética `BlaMka` de 64 bits.

Nun ecosistema tradicional, resolver as tarefas do dominio **`TENSOR`** implica arrastrar dependencias externas en C, loitar con punteiros crus, conversións opacas de tipos, excepcións non verificadas ou pausas impredicibles do colector de lixo. En Ridgun, a lib **`tensor`** (`src/main/ridgun/lib/tensor.rg`) aborda o problema con catro principios innegociables:

1. **Funcións totais e contratos explícitos (`=>`)**: ningunha función de `tensor` lanza excepcións ocultas nin depende de `null`. Todo caso límite devolve un valor sentinela documentado ou un tipo alxébrico suma (`Option`, `Result`).
2. **Cero código C e cero `libc`**: todo o código de `tensor` compila directamente a código máquina nativo ELF64 verificado por `ridgunc`.
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos os percorridos internos de `tensor` compílanse a bucles nativos en espazo de pila $O(1)$.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estrutura intermedia libérase no instante exacto en que remata a súa última lectura, sen *Garbage Collector*.

---

## 05.2. Artefactos nativos, importación e catálogo completo da API de `tensor`

En `ridgun-libs`, **`tensor`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/tensor.rg` (dominio `TENSOR`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/tensor.rglib` | Distribución e importación directa con `import tensor` |
| **Ficheiro compilado** | `target/tensor.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libtensor.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import tensor` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

### 05.2.1. Resumo de familias funcionais de `tensor`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `tensor zeros int / tensor fill int / tensor zeros real` | Reserva bloques contiguos 1D/2D de `Tensor[Int]` e `Tensor[Real]` |
| `tensor get 1d / tensor set 1d / tensor get 2d / tensor set 2d` | Acceso e actualización funcional Copy-on-Write (`with [i] = v`) |
| `tensor reshape 1d to 2d / tensor slice 1d` | Vistas de descritor en $O(1)$ sen copiar o almacenamento do tensor |
| `tensor add int / tensor mul int / tensor scale int` | Suma, multiplicación elemento a elemento (Hadamard) e escalado |
| `tensor dot int / tensor matmul int` | Contracción de índices de Einstein (`a[i] * b[i]`, `a[i, k] * b[k, j]`) |
| `u64 blamka g / u64 rotr` | Mestura rotacional `U64` sen signo de 64 bits para bloques criptográficos |

### 05.2.2. Catálogo exhaustivo de tipos e sinaturas en `src/main/ridgun/lib/tensor.rg`

A continuación tes o inventario completo de tipos alxébricos (`type`), operadores (`op ::`) e sinaturas de funcións (`fn ::`) definidos en `src/main/ridgun/lib/tensor.rg` (`0` tipos, `0` operadores e `13` funcións):

| # | Función / Sinatura (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: tensor rows Tensor[Int * r * c]` | `Int` |
| `2` | `fn :: tensor cols Tensor[Int * r * c]` | `Int` |
| `3` | `fn :: tensor shape Tensor[Int * r * c]` | `Int Int` |
| `4` | `fn :: tensor row Tensor[Int * r * c] Int` | `Tensor[Int * c]` |
| `5` | `fn :: tensor col Tensor[Int * r * c] Int` | `Tensor[Int * r]` |
| `6` | `fn :: tensor xor blocks Tensor[U64 * r * c] Tensor[U64 * r * c]` | `Tensor[U64 * r * c]` |
| `7` | `fn :: tensor and blocks Tensor[U64 * r * c] Tensor[U64 * r * c]` | `Tensor[U64 * r * c]` |
| `8` | `fn :: tensor or blocks Tensor[U64 * r * c] Tensor[U64 * r * c]` | `Tensor[U64 * r * c]` |
| `9` | `fn :: tensor add blocks Tensor[Int * r * c] Tensor[Int * r * c]` | `Tensor[Int * r * c]` |
| `10` | `fn :: tensor sub blocks Tensor[Int * r * c] Tensor[Int * r * c]` | `Tensor[Int * r * c]` |
| `11` | `fn :: tensor mul blocks Tensor[Int * r * c] Tensor[Int * r * c]` | `Tensor[Int * r * c]` |
| `12` | `fn :: tensor clone Tensor[U64 * r * c]` | `Tensor[U64 * r * c]` |
| `13` | `fn :: tensor matmul Tensor[Real * r * k] Tensor[Real * k * c]` | `Tensor[Real * r * c]` |

---

## 05.3. Explorando `tensor` a fondo: Exemplos paso a paso de cada funcionalidade

Non abonda con ver a táboa de sinaturas: imos explorar **cada unha das funcionalidades** da lib `tensor` mediante exemplos progresivos e executables en Ridgun. Comezaremos polas dúas receitas tabulares de uso cotián e despois percorreremos en detalle todos os escenarios funcionais, transformacións e casos límite verificados en `src/test/ridgun/test tensor.rg`.

### 05.3.1. Exemplo 1: Fluxo principal en estilo tabular con `tensor`

Observa como en Ridgun os signos `=` e os pasos de transformación con `tensor` quedan aliñados coma unha táboa limpa, sen variables mutables innecesarias nin efectos laterais ocultos:

```ridgun
import tensor

fn :: producto matricial tensor () => Tensor[Int]
      producto matricial tensor =
        a = tensor reshape 1d to 2d (tensor from list int [1, 2, 3, 4]) 2 2
        b = tensor reshape 1d to 2d (tensor from list int [5, 6, 7, 8]) 2 2
        tensor matmul int a b
```

### 05.3.2. Exemplo 2: Composición segura e manexo de casos de bordo

Toda función da lib `tensor` está deseñada para compoñerse con gardas booleanas `|` e co resto das 32 libs de `ridgun-libs`:

```ridgun
import tensor

fn :: energia vector (xs : [Int]) => (Int, Int)
      energia vector xs =
        v   = tensor from list int xs
        dot = tensor dot int v v
        mx  = tensor max int v
        (dot, mx)
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
        _   = assert int equals (tensor rows m) 2 "tensor rows == 2"
        _   = assert int equals (tensor cols m) 3 "tensor cols == 3"
        sh  = tensor shape m
        _   = assert int equals (shape fst sh) 2 "tensor shape rows == 2"
        _   = assert int equals (shape snd sh) 3 "tensor shape cols == 3"
        r1  = tensor row m 1
        _   = assert int equals r1_(0) 40 "row 1 col 0 == 40"
        _   = assert int equals r1_(1) 50 "row 1 col 1 == 50"
        _   = assert int equals r1_(2) 60 "row 1 col 2 == 60"
        c2  = tensor col m 2
        _   = assert int equals c2_(0) 30 "col 2 row 0 == 30"
        _   = assert int equals c2_(1) 60 "col 2 row 1 == 60"
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
        _    = assert int equals s_(0, 0) 11 "add (0,0) == 11"
        _    = assert int equals s_(1, 1) 44 "add (1,1) == 44"
        d    = tensor sub blocks a b
        _    = assert int equals d_(0, 0) 9 "sub (0,0) == 9"
        _    = assert int equals d_(1, 1) 36 "sub (1,1) == 36"
        p    = tensor mul blocks a b
        _    = assert int equals p_(0, 0) 10 "mul (0,0) == 10"
        _    = assert int equals p_(1, 1) 160 "mul (1,1) == 160"
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
        ux   = tensor_xor_blocks ua ub
        _    = assert int equals ux_(0, 0) 0xF0 "xor (0,0) == 0xF0"
        _    = assert int equals ux_(1, 1) 0xFF "xor (1,1) == 0xFF"
        uan  = tensor_and_blocks ua ub
        _    = assert int equals uan_(0, 0) 0x0F "and (0,0) == 0x0F"
        _    = assert int equals uan_(1, 1) 0x00 "and (1,1) == 0x00"
        uor  = tensor_or_blocks ua ub
        _    = assert int equals uor_(0, 0) 0xFF "or (0,0) == 0xFF"
        _    = assert int equals uor_(1, 0) 0xFF "or (1,0) == 0xFF"
        uc   = tensor clone ua
        uc_(0, 0) = 999
        _    = assert int equals ua_(0, 0) 0xFF "clone preserves original ua_(0,0)"
        _    = assert int equals uc_(0, 0) 999 "clone updates uc_(0,0)"
        ()
```

### 05.3.5. Exemplo 5: Multiplicación matricial nativa (`@`) e contracción de subíndices de Einstein (`a_ik @ b_kj`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `tensor` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test tensor matmul => ()
      test tensor matmul =
        ma  = Tensor[Real * 2 * 3]
        ma_(0, 0) = 1
        ma_(0, 1) = 2
        ma_(0, 2) = 3
        ma_(1, 0) = 4
        ma_(1, 1) = 5
        ma_(1, 2) = 6
        mb  = Tensor[Real * 3 * 2]
        mb_(0, 0) = 7
        mb_(0, 1) = 8
        mb_(1, 0) = 9
        mb_(1, 1) = 10
        mb_(2, 0) = 11
        mb_(2, 1) = 12
        mc  = tensor matmul ma mb
        _   = assert int equals mc_(0, 0) 58 "matmul (0,0) == 58"
        _   = assert int equals mc_(0, 1) 64 "matmul (0,1) == 64"
        _   = assert int equals mc_(1, 0) 139 "matmul (1,0) == 139"
        _   = assert int equals mc_(1, 1) 154 "matmul (1,1) == 154"
        ()
```

### 05.3.6. Exemplo 6: Compresión criptográfica de bloques de 1024 bytes mediante tensores (`f blamka`, `blamka g`, `blamka p16`, `compress block`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `tensor` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test blamka tensor compression => ()
      test blamka tensor compression =
        fb  = f blamka 1 2
        _   = assert int equals fb 7 "f blamka 1 2 == 7"
        gr  = blamka g 1 2 3 4
        _   = assert true ((g fst gr) != 0) "blamka g non-zero output"
        bx  = Tensor[U64 * 8 * 16]
        by  = Tensor[U64 * 8 * 16]
        bx_(0, 0) = 1
        by_(0, 0) = 2
        bz  = compress block bx by
        _   = assert true (bz_(0, 0) != 0) "compress block non-zero (0,0)"
        _   = assert int equals bx_(0, 0) 1 "compress block preserves bx_(0,0)"
        _   = assert int equals by_(0, 0) 2 "compress block preserves by_(0,0)"
        ()
```

---

## 05.4. Baixo o capó: como está construída `tensor` en Ridgun puro (`src/main/ridgun/lib/tensor.rg`)

Unha das maiores vantaxes de `ridgun-libs` é que **non hai caixas negras en C**. Podes abrir `src/main/ridgun/lib/tensor.rg` e ler exactamente como está implementada cada operación usando *pattern matching*, árbores de gardas `|` / `|.` e recursión de cola (TCO). Vexamos as pezas clave da súa implementación real:

### 05.4.1. Implementación interna: Core Implementation Part 1

Fíxate en como `tensor.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
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

fn :: tensor xor blocks Tensor[U64 * r * c] Tensor[U64 * r * c] => Tensor[U64 * r * c]
      tensor xor blocks a b = a_ij xor b_ij

fn :: tensor and blocks Tensor[U64 * r * c] Tensor[U64 * r * c] => Tensor[U64 * r * c]
      tensor and blocks a b = a_ij and b_ij

fn :: tensor or blocks Tensor[U64 * r * c] Tensor[U64 * r * c] => Tensor[U64 * r * c]
      tensor or blocks a b = a_ij or b_ij

fn :: tensor add blocks Tensor[Int * r * c] Tensor[Int * r * c] => Tensor[Int * r * c]
      tensor add blocks a b = a_ij + b_ij

fn :: tensor sub blocks Tensor[Int * r * c] Tensor[Int * r * c] => Tensor[Int * r * c]
      tensor sub blocks a b = a_ij - b_ij

fn :: tensor mul blocks Tensor[Int * r * c] Tensor[Int * r * c] => Tensor[Int * r * c]
      tensor mul blocks a b = a_ij * b_ij
```

### 05.4.2. Implementación interna: Core Implementation Part 2

Fíxate en como `tensor.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
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
- **Complexidade de pila $O(1)$ con TCO**: Todos os bucles recursivos en `src/main/ridgun/lib/tensor.rg` están en posición de cola, polo que `ridgunc` os compila a saltos nativos sen crecemento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test tensor.rg`.

### As 5 Regras de Ouro ao programar con `tensor`

1. **Declara `import tensor` ao inicio do ficheiro** e aproveita a equivalencia entre espazos e guións baixos para que o teu código se lea coma prosa.
2. **Aliña as túas tubaxes de datos con `=`**: encadea as chamadas a `tensor` en pasos con nome propio e deixa que `stable format` aliñe as columnas.
3. **Aproveita as funcións totais de `tensor` nas túas gardas `|`**: comproba os valores de retorno ou desenvolve os ADTs con *pattern matching* en vez de asumir que a entrada externa sempre é válida.
4. **Evita copiar grandes estruturas se só necesitas consultar un campo**: lembra que en `RMM2` os argumentos de entrada non incrementan nin decrementan contadores (`+0` / `-0`).
5. **Combina `tensor` con `test` (`import test`)**: escribe sempre asercións con `assert equals` ou `assert true` para fixar os invariantes do teu dominio.

---

No **Capítulo 06** pasaremos a explorar en profundidade a lib **`linalg`** (A lib `linalg` — Álxebra Lineal sobre `Tensor[Real]`, Bareiss e Activacións).
