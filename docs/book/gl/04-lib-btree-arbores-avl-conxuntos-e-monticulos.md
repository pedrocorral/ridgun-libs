# Capítulo 04: A lib `btree` — Árbores AVL Persistentes $O(\log N)$, Conxuntos e Montículos

## 1. Por que existe a lib `btree`?

Sexamos sinceros: as táboas hash mutables sofren ataques de colisión de chaves (HashDoS), non manteñen as chaves ordenadas para consultas por rango e non se poden compartir entre actores sen copialas enteiras ou meter un cadeado.

A lib **`btree`** implementa tres estruturas de datos funcionais persistentes en $O(\log N)$ con compartición estrutural: **`BTreeMap`** (árbore AVL autobalanceada), **`BTreeSet`** (álxebra de conxuntos ordenada) e **`MinHeap`** (fila de prioridade *leftist heap*).

---

## 2. Artefactos, importación e arquitectura sen `libc`

En `ridgun-libs`, **`btree`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/btree.rg` (dominio `BTREE`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/btree.rglib` | Distribución e importación directa con `import btree` |
| **Ficheiro compilado** | `target/btree.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libbtree.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import btree` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

---

## 3. Referencia rápida da API de `btree`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `btree empty / btree insert / btree get / btree remove` | Busca, inserción e borrado persistente en dicionario AVL en $O(\log N)$ |
| `btree min key / btree max key / btree range` | Extremos ordenados e consulta por rango `[lo, hi]` |
| `bset from list / bset union / bset intersect / bset diff` | Álxebra de conxuntos ordenados (`BTreeSet`) e predicado de subconxunto |
| `heap empty / heap push / heap peek / heap pop / heap sort` | Fila de prioridade `MinHeap` (*leftist heap*) con fusión en $O(\log N)$ |

---

## 4. Receitas prácticas en estilo tabular

### Receita 1: Fluxo principal con `btree`

Observa como os signos `=` e os pasos de transformación quedan aliñados coma unha táboa limpa:

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

### Receita 2: Composición segura e sen efectos laterais

Toda función da lib `btree` é compoñible co resto das 32 libs de `ridgun-libs`:

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

## 5. Baixo o capó: rendemento, memoria RMM e garantías

- **Garantía algorítmica e de seguridade**: Rotacións AVL estritas (`height diff <= 1`), inmunidade total a HashDoS, consultas por rango en $O(\log N + K)$ e fusión de montículos en $O(\log N)$.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test_btree.rg`.
