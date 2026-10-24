# Capítol 05: La lib `tensor` — Tensors Multidimensionals, Vistes i Contracció d'Einstein

## 1. Per què existeix la lib `tensor`?

Siguem sincers: en la majoria de llenguatges has de triar entre llistes imbricades lentíssimes plenes de punters dispersos o enllaçar una mola de C++/Fortran de 200 MB com NumPy/BLAS.

La lib **`tensor`** embolcalla la primitiva nativa `Tensor[...]` de Ridgun oferint creació tipada (`Tensor[Int]`, `Tensor[Real]`, `Tensor[U64]`), vistes sense còpia (`reshape`, `slice`), operacions element a element (Hadamard), contracció d'Einstein (`*` sobre eixos simbòlics) i aritmètica `BlaMka` de 64 bits.

---

## 2. Artefactes, importació i arquitectura sense `libc`

A `ridgun-libs`, **`tensor`** és una **lib** de primera classe situada a `src/main/ridgun/lib/tensor.rg` (domini `TENSOR`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/tensor.rglib` | Distribució i importació directa amb `import tensor` |
| **Fitxer compilat** | `target/tensor.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libtensor.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Per fer servir aquesta lib en qualsevol fitxer `.rg`, n'hi ha prou de declarar `import tensor` a la capçalera i cridar les seves funcions amb espais o guions baixos indistintament.

---

## 3. Referència ràpida de l'API de `tensor`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `tensor zeros int / tensor fill int / tensor zeros real` | Reserva blocs contigus 1D/2D de `Tensor[Int]` i `Tensor[Real]` |
| `tensor get 1d / tensor set 1d / tensor get 2d / tensor set 2d` | Accés i actualització funcional Copy-on-Write (`with [i] = v`) |
| `tensor reshape 1d to 2d / tensor slice 1d` | Vistes de descriptor en $O(1)$ sense copiar l'emmagatzematge del tensor |
| `tensor add int / tensor mul int / tensor scale int` | Suma, multiplicació element a element (Hadamard) i escalat |
| `tensor dot int / tensor matmul int` | Contracció d'índexs d'Einstein (`a[i] * b[i]`, `a[i, k] * b[k, j]`) |
| `u64 blamka g / u64 rotr` | Mescla rotacional `U64` sense signe de 64 bits per a blocs criptogràfics |

---

## 4. Receptes pràctiques en estil tabular

### Recepta 1: Flux principal amb `tensor`

Observa com els signes `=` i els passos de transformació queden alineats com una taula neta:

```ridgun
import tensor

fn :: producto matricial tensor () => Tensor[Int]
      producto matricial tensor =
        a = tensor reshape 1d to 2d (tensor from list int [1, 2, 3, 4]) 2 2
        b = tensor reshape 1d to 2d (tensor from list int [5, 6, 7, 8]) 2 2
        tensor matmul int a b
```

### Recepta 2: Composició segura i sense efectes laterals

Tota funció de la lib `tensor` és componible amb la resta de les 32 libs de `ridgun-libs`:

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

## 5. Sota el capó: rendiment, memòria RMM i garanties

- **Garantia algorísmica i de seguretat**: Memòria contigua de 8 bytes per cel·la gestionada estàticament per RMM1/RMM2, vistes en $O(1)$ sense duplicar el búfer i semàntica pura Copy-on-Write.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test_tensor.rg`.
