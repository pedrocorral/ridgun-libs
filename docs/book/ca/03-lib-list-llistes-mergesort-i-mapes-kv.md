# Capítol 03: La lib `list` — Llistes, Mergesort $O(N \log N)$ i Mapes Clau-Valor

## 1. Per què existeix la lib `list`?

Siguem sincers: accedir a un índex fora de rang (`IndexError` / `panic!`) o mutar una llista compartida per accident són dos dels errors més freqüents en processar col·leccions.

La lib **`list`** proporciona indexació amb valor per defecte, llescat (`take`, `drop`, `slice`), rangs amb pas, deduplicació estable, ordenació **mergesort $O(N \log N)$** per a `[Int]` i `[String]`, i diccionaris associatius immutables `[String String]` (`kv get`, `kv put`, `kv merge`).

---

## 2. Artefactes, importació i arquitectura sense `libc`

A `ridgun-libs`, **`list`** és una **lib** de primera classe situada a `src/main/ridgun/lib/list.rg` (domini `LIST`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/list.rglib` | Distribució i importació directa amb `import list` |
| **Fitxer compilat** | `target/list.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/liblist.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Per fer servir aquesta lib en qualsevol fitxer `.rg`, n'hi ha prou de declarar `import list` a la capçalera i cridar les seves funcions amb espais o guions baixos indistintament.

---

## 3. Referència ràpida de l'API de `list`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `list nth or / list str nth or` | Lectura segura per índex retornant `default_val` si està fora de rang |
| `list take / list drop / list slice / list reverse` | Prefix, sufix, subrang `[start, end)` i inversió recursiva de cua |
| `list range / list range step` | Genera seqüències aritmètiques (`step == 0` retorna `[]` de forma segura) |
| `list sort / list str sort / list dedup / list str dedup` | Ordenació mergesort $O(N \log N)$ estable i deduplicació per primera aparició |
| `kv empty / kv put / kv get / kv get or / kv remove / kv merge` | Operacions sobre diccionaris associatius ordenats `[String String]` |

---

## 4. Receptes pràctiques en estil tabular

### Recepta 1: Flux principal amb `list`

Observa com els signes `=` i els passos de transformació queden alineats com una taula neta:

```ridgun
import list

fn :: top tres unicos (puntos : [Int]) => [Int]
      top tres unicos puntos =
        unicos    = list dedup puntos
        ordenados = list reverse (list sort unicos)
        list take ordenados 3
```

### Recepta 2: Composició segura i sense efectes laterals

Tota funció de la lib `list` és componible amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import list

fn :: configurar entorno (base : [String String]) => (String, [String])
      configurar entorno base =
        cfg1 = kv put base "host" "0.0.0.0"
        cfg2 = kv put cfg1 "port" "8080"
        host = kv get or cfg2 "host" "127.0.0.1"
        (host, kv keys cfg2)
```

---

## 5. Sota el capó: rendiment, memòria RMM i garanties

- **Garantia algorísmica i de seguretat**: Ordenació determinista $O(N \log N)$ en el pitjor cas (sense l'$O(N^2)$ patològic de Quicksort) i preservació de l'ordre d'inserció en mapes `kv`.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test_list.rg`.
