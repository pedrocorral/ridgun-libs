# 05. kapitulua: `tensor` lib-a — Dimentsio Anitzeko Tentsoreak, Bistak eta Einsteinen Uzkurdura

## 1. Zergatik existitzen da `tensor` lib-a?

Izan gaitezen zintzoak: lengoaia gehienetan erakusle sakabanatuz betetako zerrenda habiaratu motel-motelen edo NumPy/BLAS bezalako 200 MB-ko C++/Fortran bloke erraldoi bat estekatzearen artean aukeratu behar duzu.

**`tensor`** lib-ak Ridgunen `Tensor[...]` primitiba natiboa biltzen du, sorrera tipatua (`Tensor[Int]`, `Tensor[Real]`, `Tensor[U64]`), kopiarik gabeko bistak (`reshape`, `slice`), elementuz elementuko eragiketak (Hadamard), Einsteinen uzkurdura eta 64 biteko `BlaMka` aritmetika eskainiz.

---

## 2. Artefaktuak, inportazioa eta `libc` gabeko arkitektura

`ridgun-libs`-en, **`tensor`** lehen mailako **lib** bat da, `src/main/ridgun/lib/tensor.rg` bidean kokatua (`TENSOR` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/tensor.rglib` | Banaketa eta inportazio zuzena `import tensor` bidez |
| **Fitxategi konpilatua** | `target/tensor.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libtensor.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import tensor` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

---

## 3. `tensor` APIaren erreferentzia azkarra

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `tensor zeros int / tensor fill int / tensor zeros real` | 1D/2D `Tensor[Int]` eta `Tensor[Real]` bloke jarraituak esleitzen ditu |
| `tensor get 1d / tensor set 1d / tensor get 2d / tensor set 2d` | Copy-on-Write (`with [i] = v`) elementuen sarbide eta eguneratze funtzionala |
| `tensor reshape 1d to 2d / tensor slice 1d` | $O(1)$ deskribatzaile-bistak tentsorearen biltegia kopiatu gabe |
| `tensor add int / tensor mul int / tensor scale int` | Elementuz elementuko batuketa, biderketa (Hadamard) eta eskalatzea |
| `tensor dot int / tensor matmul int` | Einsteinen indize-uzkurdura (`a[i] * b[i]`, `a[i, k] * b[k, j]`) |
| `u64 blamka g / u64 rotr` | 64 biteko zeinurik gabeko `U64` nahasketa birakaria bloke kriptografikoetarako |

---

## 4. Errezeta praktikoak estilo taularatuan

### 1. errezeta: Fluxu nagusia `tensor` erabiliz

Ikusi nola `=` ikurrak eta eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren:

```ridgun
import tensor

fn :: producto matricial tensor () => Tensor[Int]
      producto matricial tensor =
        a = tensor reshape 1d to 2d (tensor from list int [1, 2, 3, 4]) 2 2
        b = tensor reshape 1d to 2d (tensor from list int [5, 6, 7, 8]) 2 2
        tensor matmul int a b
```

### 2. errezeta: Konposizio segurua eta albo-ondoriorik gabea

`tensor` lib-eko funtzio oro `ridgun-libs`-eko gainerako 32 lib-ekin konposa daiteke:

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

## 5. Kaputaren azpian: errendimendua, RMM memoria eta bermeak

- **Berme algoritmikoa eta segurtasunekoa**: RMM1/RMM2-k estatikoki kudeatutako gelaxkako 8 byteko memoria jarraitua, $O(1)$ bistak bufferra bikoiztu gabe eta Copy-on-Write semantika hutsa.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test_tensor.rg` suite automatizatuaren bidez.
