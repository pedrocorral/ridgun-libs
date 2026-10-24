# Capítol 04: La lib `btree` — Arbres AVL Persistents $O(\log N)$, Conjunts i Monticles

## 1. Per què existeix la lib `btree`?

Siguem sincers: les taules hash mutables pateixen atacs de col·lisió de claus (HashDoS), no mantenen les claus ordenades per a consultes per rang i no es poden compartir entre actors sense copiar-les senceres o posar-hi un cadenat.

La lib **`btree`** implementa tres estructures de dades funcionals persistents en $O(\log N)$ amb compartició estructural: **`BTreeMap`** (arbre AVL autobalancejat), **`BTreeSet`** (àlgebra de conjunts ordenada) i **`MinHeap`** (cua de prioritat *leftist heap*).

---

## 2. Artefactes, importació i arquitectura sense `libc`

A `ridgun-libs`, **`btree`** és una **lib** de primera classe situada a `src/main/ridgun/lib/btree.rg` (domini `BTREE`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/btree.rglib` | Distribució i importació directa amb `import btree` |
| **Fitxer compilat** | `target/btree.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libbtree.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Per fer servir aquesta lib en qualsevol fitxer `.rg`, n'hi ha prou de declarar `import btree` a la capçalera i cridar les seves funcions amb espais o guions baixos indistintament.

---

## 3. Referència ràpida de l'API de `btree`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `btree empty / btree insert / btree get / btree remove` | Cerca, inserció i esborrat persistent en diccionari AVL en $O(\log N)$ |
| `btree min key / btree max key / btree range` | Extrems ordenats i consulta per rang `[lo, hi]` |
| `bset from list / bset union / bset intersect / bset diff` | Àlgebra de conjunts ordenats (`BTreeSet`) i predicat de subconjunt |
| `heap empty / heap push / heap peek / heap pop / heap sort` | Cua de prioritat `MinHeap` (*leftist heap*) amb fusió en $O(\log N)$ |

---

## 4. Receptes pràctiques en estil tabular

### Recepta 1: Flux principal amb `btree`

Observa com els signes `=` i els passos de transformació queden alineats com una taula neta:

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

### Recepta 2: Composició segura i sense efectes laterals

Tota funció de la lib `btree` és componible amb la resta de les 32 libs de `ridgun-libs`:

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

## 5. Sota el capó: rendiment, memòria RMM i garanties

- **Garantia algorísmica i de seguretat**: Rotacions AVL estrictes (`height diff <= 1`), immunitat total a HashDoS, consultes per rang en $O(\log N + K)$ i fusió de monticles en $O(\log N)$.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test_btree.rg`.
