# Capítulo 05: La lib `tensor` — Tensores Multidimensionales, Vistas y Contracción de Einstein

## 1. ¿Por qué existe la lib `tensor`?

Seamos sinceros: en la mayoría de lenguajes tienes que elegir entre listas anidadas lentísimas llenas de punteros dispersos o enlazar una mole de C++/Fortran de 200 MB como NumPy/BLAS.

La lib **`tensor`** envuelve la primitiva nativa `Tensor[...]` de Ridgun ofreciendo creación tipada (`Tensor[Int]`, `Tensor[Real]`, `Tensor[U64]`), vistas sin copia (`reshape`, `slice`), operaciones elemento a elemento (Hadamard), contracción de Einstein (`*` sobre ejes simbólicos) y aritmética `BlaMka` de 64 bits.

---

## 2. Artefactos, importación y arquitectura sin `libc`

En `ridgun-libs`, **`tensor`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/tensor.rg` (dominio `TENSOR`). Al compilar con `stable bundle`, se empaqueta en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/tensor.rglib` | Distribución e importación directa con `import tensor` |
| **Archivo compilado** | `target/tensor.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libtensor.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import tensor` en el encabezado y llamar a sus funciones con espacios o guiones bajos indistintamente.

---

## 3. Referencia rápida de la API de `tensor`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `tensor zeros int / tensor fill int / tensor zeros real` | Reserva bloques contiguos 1D/2D de `Tensor[Int]` y `Tensor[Real]` |
| `tensor get 1d / tensor set 1d / tensor get 2d / tensor set 2d` | Acceso y actualización funcional Copy-on-Write (`with [i] = v`) |
| `tensor reshape 1d to 2d / tensor slice 1d` | Vistas de descriptor en $O(1)$ sin copiar el almacenamiento del tensor |
| `tensor add int / tensor mul int / tensor scale int` | Suma, multiplicación elemento a elemento (Hadamard) y escalado |
| `tensor dot int / tensor matmul int` | Contracción de índices de Einstein (`a[i] * b[i]`, `a[i, k] * b[k, j]`) |
| `u64 blamka g / u64 rotr` | Mezcla rotacional `U64` sin signo de 64 bits para bloques criptográficos |

---

## 4. Recetas prácticas en estilo tabular

### Receta 1: Flujo principal con `tensor`

Observa cómo los signos `=` y los pasos de transformación quedan alineados como una tabla limpia:

```ridgun
import tensor

fn :: producto matricial tensor () => Tensor[Int]
      producto matricial tensor =
        a = tensor reshape 1d to 2d (tensor from list int [1, 2, 3, 4]) 2 2
        b = tensor reshape 1d to 2d (tensor from list int [5, 6, 7, 8]) 2 2
        tensor matmul int a b
```

### Receta 2: Composición segura y sin efectos laterales

Toda función de la lib `tensor` es componible con el resto de las 32 libs de `ridgun-libs`:

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

## 5. Bajo el capó: rendimiento, memoria RMM y garantías

- **Garantía algorítmica y de seguridad**: Memoria contigua de 8 bytes por celda gestionada estáticamente por RMM1/RMM2, vistas en $O(1)$ sin duplicar el búfer y semántica pura Copy-on-Write.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test_tensor.rg`.
