# Capítulo 05: A lib `tensor` — Tensores Multidimensionais, Vistas e Contracción de Einstein

## 1. Por que existe a lib `tensor`?

Sexamos sinceros: na maioría de linguaxes tes que escoller entre listas aniñadas lentísimas cheas de punteiros dispersos ou enlazar unha mole de C++/Fortran de 200 MB coma NumPy/BLAS.

A lib **`tensor`** envolve a primitiva nativa `Tensor[...]` de Ridgun ofrecendo creación tipada (`Tensor[Int]`, `Tensor[Real]`, `Tensor[U64]`), vistas sen copia (`reshape`, `slice`), operacións elemento a elemento (Hadamard), contracción de Einstein (`*` sobre eixos simbólicos) e aritmética `BlaMka` de 64 bits.

---

## 2. Artefactos, importación e arquitectura sen `libc`

En `ridgun-libs`, **`tensor`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/tensor.rg` (dominio `TENSOR`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/tensor.rglib` | Distribución e importación directa con `import tensor` |
| **Ficheiro compilado** | `target/tensor.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libtensor.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import tensor` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

---

## 3. Referencia rápida da API de `tensor`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `tensor zeros int / tensor fill int / tensor zeros real` | Reserva bloques contiguos 1D/2D de `Tensor[Int]` e `Tensor[Real]` |
| `tensor get 1d / tensor set 1d / tensor get 2d / tensor set 2d` | Acceso e actualización funcional Copy-on-Write (`with [i] = v`) |
| `tensor reshape 1d to 2d / tensor slice 1d` | Vistas de descritor en $O(1)$ sen copiar o almacenamento do tensor |
| `tensor add int / tensor mul int / tensor scale int` | Suma, multiplicación elemento a elemento (Hadamard) e escalado |
| `tensor dot int / tensor matmul int` | Contracción de índices de Einstein (`a[i] * b[i]`, `a[i, k] * b[k, j]`) |
| `u64 blamka g / u64 rotr` | Mestura rotacional `U64` sen signo de 64 bits para bloques criptográficos |

---

## 4. Receitas prácticas en estilo tabular

### Receita 1: Fluxo principal con `tensor`

Observa como os signos `=` e os pasos de transformación quedan aliñados coma unha táboa limpa:

```ridgun
import tensor

fn :: producto matricial tensor () => Tensor[Int]
      producto matricial tensor =
        a = tensor reshape 1d to 2d (tensor from list int [1, 2, 3, 4]) 2 2
        b = tensor reshape 1d to 2d (tensor from list int [5, 6, 7, 8]) 2 2
        tensor matmul int a b
```

### Receita 2: Composición segura e sen efectos laterais

Toda función da lib `tensor` é compoñible co resto das 32 libs de `ridgun-libs`:

```ridgun
import tensor

fn :: energia vector (xs : [Int]) => (Int, Int)
      energia vector xs =
        v   = tensor from list int xs
        dot = tensor dot int v v
        mx  = tensor max int v
        (dot, mx)
```

---

## 5. Baixo o capó: rendemento, memoria RMM e garantías

- **Garantía algorítmica e de seguridade**: Memoria contigua de 8 bytes por cela xestionada estaticamente por RMM1/RMM2, vistas en $O(1)$ sen duplicar o búfer e semántica pura Copy-on-Write.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test_tensor.rg`.
