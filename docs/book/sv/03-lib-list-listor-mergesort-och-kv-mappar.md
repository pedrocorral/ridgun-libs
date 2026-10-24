# Kapitel 03: Lib:en `list` — Listor, $O(N \log N)$ Mergesort och Nyckel-Värde-Mappar

## 1. Varför finns lib:en `list`?

Låt oss vara ärliga: indexfel utanför gränserna (`IndexError` / `panic!`) och oavsiktlig mutering av delade listor är två av de vanligaste buggarna vid databearbetning.

Lib:en **`list`** tillhandahåller säker indexering med standardvärde, skivning (`take`, `drop`, `slice`), intervall, stabil deduplicering, **$O(N \log N)$ mergesort** för `[Int]` och `[String]` samt oföränderliga `[String String]`-nyckel-värde-mappar (`kv get`, `kv put`, `kv merge`).

---

## 2. Paket, import och arkitektur helt utan `libc`

I `ridgun-libs` är **`list`** en förstklassig **lib** placerad i `src/main/ridgun/lib/list.rg` (domän `LIST`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/list.rglib` | Portabel distribution och direkt import med `import list` |
| **Kompilerat arkiv** | `target/list.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/liblist.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import list` överst och anropar funktionerna med mellanslag eller understreck.

---

## 3. Snabbreferens för `list`-API:et

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `list nth or / list str nth or` | Säker indexuppslagning som returnerar `default_val` utanför gränserna |
| `list take / list drop / list slice / list reverse` | Prefix, suffix, delintervall `[start, end)` och svansrekursiv omvändning |
| `list range / list range step` | Genererar aritmetiska talföljder (`step == 0` returnerar säkert `[]`) |
| `list sort / list str sort / list dedup / list str dedup` | Stabil $O(N \log N)$ mergesort och deduplicering vid första förekomst |
| `kv empty / kv put / kv get / kv get or / kv remove / kv merge` | Operationer på ordnade associativa `[String String]`-nyckel-värde-mappar |

---

## 4. Praktiska recept i tabellform

### Recept 1: Huvudflöde med `list`

Lägg märke till hur `=`-tecknen och transformationsstegen linjeras som en ren tabell:

```ridgun
import list

fn :: top tres unicos (puntos : [Int]) => [Int]
      top tres unicos puntos =
        unicos    = list dedup puntos
        ordenados = list reverse (list sort unicos)
        list take ordenados 3
```

### Recept 2: Säker komposition utan sidoeffekter

Varje funktion i lib:en `list` kan kombineras fritt med övriga 32 libs i `ridgun-libs`:

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

## 5. Under huven: prestanda, RMM-minne och garantier

- **Algoritmisk garanti och säkerhet**: Deterministisk $O(N \log N)$-sortering i värsta fall (immun mot Quicksorts patologiska $O(N^2)$) och bevarad insättningsordning i `kv`-mappar.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test_list.rg`.
