# Kapitel 04: Lib:en `btree` — Beständiga $O(\log N)$ AVL-Träd, Mängder och Prioritetsköer

## 1. Varför finns lib:en `btree`?

Låt oss vara ärliga: muterbara hashtabeller är sårbara för hashkollisionsattacker (HashDoS), håller inte nycklar sorterade för intervallfrågor och kan inte delas säkert mellan aktörer utan lås.

Lib:en **`btree`** implementerar tre beständiga funktionella datastrukturer i $O(\log N)$ med strukturell delning: **`BTreeMap`** (självbalanserande AVL-träd), **`BTreeSet`** (ordnad mängdalgebra) och **`MinHeap`** (*leftist heap*-prioritetskö).

---

## 2. Paket, import och arkitektur helt utan `libc`

I `ridgun-libs` är **`btree`** en förstklassig **lib** placerad i `src/main/ridgun/lib/btree.rg` (domän `BTREE`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/btree.rglib` | Portabel distribution och direkt import med `import btree` |
| **Kompilerat arkiv** | `target/btree.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libbtree.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import btree` överst och anropar funktionerna med mellanslag eller understreck.

---

## 3. Snabbreferens för `btree`-API:et

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `btree empty / btree insert / btree get / btree remove` | Beständig $O(\log N)$ AVL-uppslagning, insättning och borttagning |
| `btree min key / btree max key / btree range` | Ordnade extremvärden och intervallfråga `[lo, hi]` |
| `bset from list / bset union / bset intersect / bset diff` | Ordnad mängdalgebra (`BTreeSet`) och delmängdspredikat |
| `heap empty / heap push / heap peek / heap pop / heap sort` | Prioritetskö `MinHeap` (*leftist heap*) med sammanslagning i $O(\log N)$ |

---

## 4. Praktiska recept i tabellform

### Recept 1: Huvudflöde med `btree`

Lägg märke till hur `=`-tecknen och transformationsstegen linjeras som en ren tabell:

```ridgun
import btree

fn :: consultar rango precios () => [String String]
      consultar rango precios =
        t0 = btree empty
        t1 = btree insert t0 "item:10" "Teclado"
        t2 = btree insert t1 "item:20" "Monitor"
        t3 = btree insert t2 "item:30" "Raton"
        btree range t3 "item:10" "item:25"
```

### Recept 2: Säker komposition utan sidoeffekter

Varje funktion i lib:en `btree` kan kombineras fritt med övriga 32 libs i `ridgun-libs`:

```ridgun
import btree

fn :: despachar urgente () => (Int, String)
      despachar urgente =
        h0 = heap empty
        h1 = heap push h0 50 "backup-nocturno"
        h2 = heap push h1 10 "alerta-seguridad"
        h3 = heap push h2 30 "rotar-logs"
        heap peek h3
```

---

## 5. Under huven: prestanda, RMM-minne och garantier

- **Algoritmisk garanti och säkerhet**: Strikt AVL-balansering (`height diff <= 1`), fullständig immunitet mot HashDoS, intervallfrågor i $O(\log N + K)$ och sammanslagning av heaps i $O(\log N)$.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test_btree.rg`.
