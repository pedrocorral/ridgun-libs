# 04. kapitulua: `btree` lib-a — $O(\log N)$ AVL Zuhaitz Iraunkorrak, Multzoak eta Tontorrak

## 1. Zergatik existitzen da `btree` lib-a?

Izan gaitezen zintzoak: hash-taula aldakorrek gako-talka erasoak (HashDoS) jasaten dituzte, ez dituzte gakoak ordenatuta mantentzen tarte-kontsultetarako eta ezin dira aktoreen artean partekatu blokeorik gabe.

**`btree`** lib-ak egitura-partekatzea duten $O(\log N)$ hiru datu-egitura funtzional iraunkor inplementatzen ditu: **`BTreeMap`** (bere kabuz orekatzen den AVL zuhaitza), **`BTreeSet`** (multzo-aljebra ordenatua) eta **`MinHeap`** (*leftist heap* lehentasun-ilara).

---

## 2. Artefaktuak, inportazioa eta `libc` gabeko arkitektura

`ridgun-libs`-en, **`btree`** lehen mailako **lib** bat da, `src/main/ridgun/lib/btree.rg` bidean kokatua (`BTREE` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/btree.rglib` | Banaketa eta inportazio zuzena `import btree` bidez |
| **Fitxategi konpilatua** | `target/btree.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libbtree.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import btree` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

---

## 3. `btree` APIaren erreferentzia azkarra

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `btree empty / btree insert / btree get / btree remove` | $O(\log N)$ AVL hiztegi iraunkorreko bilaketa, txertaketa eta ezabaketa |
| `btree min key / btree max key / btree range` | Mutur ordenatuak eta `[lo, hi]` tarte-kontsulta |
| `bset from list / bset union / bset intersect / bset diff` | Multzo ordenatuen aljebra (`BTreeSet`) eta azpimultzo-predikatua |
| `heap empty / heap push / heap peek / heap pop / heap sort` | `MinHeap` lehentasun-ilara (*leftist heap*) $O(\log N)$ batuketarekin |

---

## 4. Errezeta praktikoak estilo taularatuan

### 1. errezeta: Fluxu nagusia `btree` erabiliz

Ikusi nola `=` ikurrak eta eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren:

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

### 2. errezeta: Konposizio segurua eta albo-ondoriorik gabea

`btree` lib-eko funtzio oro `ridgun-libs`-eko gainerako 32 lib-ekin konposa daiteke:

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

## 5. Kaputaren azpian: errendimendua, RMM memoria eta bermeak

- **Berme algoritmikoa eta segurtasunekoa**: AVL biraketa zorrotzak (`height diff <= 1`), HashDoS-en aurkako immunitate osoa, tarte-kontsultak $O(\log N + K)$-n eta tontorren batuketa $O(\log N)$-n.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test_btree.rg` suite automatizatuaren bidez.
