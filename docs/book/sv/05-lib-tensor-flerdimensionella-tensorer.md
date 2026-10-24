# Kapitel 05: Lib:en `tensor` — Flerdimensionella Tensorer, Vyer och Einsteinkontraktion

## 1. Varför finns lib:en `tensor`?

Låt oss vara ärliga: i de flesta språk måste du välja mellan långsamma nästlade listor fulla av pekare eller att länka in ett C++/Fortran-paket på 200 MB som NumPy/BLAS.

Lib:en **`tensor`** kapslar in Ridguns inbyggda `Tensor[...]`-primitiv med typade konstruktörer (`Tensor[Int]`, `Tensor[Real]`, `Tensor[U64]`), kopieringsfria vyer (`reshape`, `slice`), elementvisa Hadamard-operationer, Einsteinkontraktion och 64-bitars `BlaMka`-aritmetik.

---

## 2. Paket, import och arkitektur helt utan `libc`

I `ridgun-libs` är **`tensor`** en förstklassig **lib** placerad i `src/main/ridgun/lib/tensor.rg` (domän `TENSOR`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/tensor.rglib` | Portabel distribution och direkt import med `import tensor` |
| **Kompilerat arkiv** | `target/tensor.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libtensor.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import tensor` överst och anropar funktionerna med mellanslag eller understreck.

---

## 3. Snabbreferens för `tensor`-API:et

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `tensor zeros int / tensor fill int / tensor zeros real` | Allokerar sammanhängande 1D/2D-block av `Tensor[Int]` och `Tensor[Real]` |
| `tensor get 1d / tensor set 1d / tensor get 2d / tensor set 2d` | Funktionell Copy-on-Write-åtkomst och uppdatering (`with [i] = v`) |
| `tensor reshape 1d to 2d / tensor slice 1d` | $O(1)$-deskriptorvyer utan att kopiera tensorns underliggande lagring |
| `tensor add int / tensor mul int / tensor scale int` | Elementvis Hadamard-addition, multiplikation och skalning |
| `tensor dot int / tensor matmul int` | Einsteinkontraktion över index (`a[i] * b[i]`, `a[i, k] * b[k, j]`) |
| `u64 blamka g / u64 rotr` | 64-bitars teckenlös `U64`-rotationsblandning för kryptografiska block |

---

## 4. Praktiska recept i tabellform

### Recept 1: Huvudflöde med `tensor`

Lägg märke till hur `=`-tecknen och transformationsstegen linjeras som en ren tabell:

```ridgun
import tensor

fn :: producto matricial tensor () => Tensor[Int]
      producto matricial tensor =
        a = tensor reshape 1d to 2d (tensor from list int [1, 2, 3, 4]) 2 2
        b = tensor reshape 1d to 2d (tensor from list int [5, 6, 7, 8]) 2 2
        tensor matmul int a b
```

### Recept 2: Säker komposition utan sidoeffekter

Varje funktion i lib:en `tensor` kan kombineras fritt med övriga 32 libs i `ridgun-libs`:

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

## 5. Under huven: prestanda, RMM-minne och garantier

- **Algoritmisk garanti och säkerhet**: Sammanhängande 8-bytesjusterat minne statiskt hanterat av RMM1/RMM2, $O(1)$-vyer utan buffertkopiering och ren Copy-on-Write-semantik.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test_tensor.rg`.
