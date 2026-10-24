# Capítulo 03: A lib `list` — Listas, Mergesort $O(N \log N)$ e Mapas Chave-Valor

## 1. Por que existe a lib `list`?

Sexamos sinceros: acceder a un índice fóra de rango (`IndexError` / `panic!`) ou mutar unha lista compartida por accidente son dous dos erros máis frecuentes ao procesar coleccións.

A lib **`list`** proporciona indexación con valor por defecto, rebandado (`take`, `drop`, `slice`), rangos con paso, deduplicación estable, ordenación **mergesort $O(N \log N)$** para `[Int]` e `[String]`, e dicionarios asociativos inmutables `[String String]` (`kv get`, `kv put`, `kv merge`).

---

## 2. Artefactos, importación e arquitectura sen `libc`

En `ridgun-libs`, **`list`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/list.rg` (dominio `LIST`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/list.rglib` | Distribución e importación directa con `import list` |
| **Ficheiro compilado** | `target/list.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/liblist.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import list` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

---

## 3. Referencia rápida da API de `list`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `list nth or / list str nth or` | Lectura segura por índice devolvendo `default_val` se está fóra de rango |
| `list take / list drop / list slice / list reverse` | Prefixo, sufixo, subrango `[start, end)` e inversión recursiva de cola |
| `list range / list range step` | Xera secuencias aritméticas (`step == 0` devolve `[]` de forma segura) |
| `list sort / list str sort / list dedup / list str dedup` | Ordenación mergesort $O(N \log N)$ estable e deduplicación por primeira aparición |
| `kv empty / kv put / kv get / kv get or / kv remove / kv merge` | Operacións sobre dicionarios asociativos ordenados `[String String]` |

---

## 4. Receitas prácticas en estilo tabular

### Receita 1: Fluxo principal con `list`

Observa como os signos `=` e os pasos de transformación quedan aliñados coma unha táboa limpa:

```ridgun
import list

fn :: top tres unicos (puntos : [Int]) => [Int]
      top tres unicos puntos =
        unicos    = list dedup puntos
        ordenados = list reverse (list sort unicos)
        list take ordenados 3
```

### Receita 2: Composición segura e sen efectos laterais

Toda función da lib `list` é compoñible co resto das 32 libs de `ridgun-libs`:

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

## 5. Baixo o capó: rendemento, memoria RMM e garantías

- **Garantía algorítmica e de seguridade**: Ordenación determinista $O(N \log N)$ no peor caso (sen o $O(N^2)$ patolóxico de Quicksort) e preservación da orde de inserción en mapas `kv`.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test_list.rg`.
