# 03. kapitulua: `list` lib-a — Zerrendak, $O(N \log N)$ Mergesort eta Gako-Balio Mapak

## 1. Zergatik existitzen da `list` lib-a?

Izan gaitezen zintzoak: tartetik kanpoko indize batera sartzea (`IndexError` / `panic!`) edo partekatutako zerrenda bat ustekabean mutatzea bildumak prozesatzeko orduan gertatzen diren akats ohikoenetako bi dira.

**`list`** lib-ak lehenetsitako balio bidezko indexazioa, zatitzea (`take`, `drop`, `slice`), urrats bidezko tarteak, deduplikazio egonkorra, `[Int]` eta `[String]`-entzako **$O(N \log N)$ mergesort** ordenazioa eta `[String String]` hiztegi elkartu aldaezinak eskaintzen ditu.

---

## 2. Artefaktuak, inportazioa eta `libc` gabeko arkitektura

`ridgun-libs`-en, **`list`** lehen mailako **lib** bat da, `src/main/ridgun/lib/list.rg` bidean kokatua (`LIST` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/list.rglib` | Banaketa eta inportazio zuzena `import list` bidez |
| **Fitxategi konpilatua** | `target/list.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/liblist.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import list` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

---

## 3. `list` APIaren erreferentzia azkarra

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `list nth or / list str nth or` | Indize bidezko irakurketa segurua, tartetik kanpo `default_val` itzuliz |
| `list take / list drop / list slice / list reverse` | Aurrizkia, atzizkia, `[start, end)` azpitartea eta buztan-errekurtsioko alderantzikatzea |
| `list range / list range step` | Sekuentzia aritmetikoak sortzen ditu (`step == 0`-k `[]` itzultzen du seguru) |
| `list sort / list str sort / list dedup / list str dedup` | $O(N \log N)$ mergesort ordenazio egonkorra eta lehen agerpeneko deduplikazioa |
| `kv empty / kv put / kv get / kv get or / kv remove / kv merge` | `[String String]` hiztegi elkartu ordenatuen gaineko eragiketak |

---

## 4. Errezeta praktikoak estilo taularatuan

### 1. errezeta: Fluxu nagusia `list` erabiliz

Ikusi nola `=` ikurrak eta eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren:

```ridgun
import list

fn :: top tres unicos (puntos : [Int]) => [Int]
      top tres unicos puntos =
        unicos    = list dedup puntos
        ordenados = list reverse (list sort unicos)
        list take ordenados 3
```

### 2. errezeta: Konposizio segurua eta albo-ondoriorik gabea

`list` lib-eko funtzio oro `ridgun-libs`-eko gainerako 32 lib-ekin konposa daiteke:

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

## 5. Kaputaren azpian: errendimendua, RMM memoria eta bermeak

- **Berme algoritmikoa eta segurtasunekoa**: Kasurik txarreneko $O(N \log N)$ ordenazio determinista (Quicksorten $O(N^2)$ patologikorik gabe) eta txertatze-ordenaren kontserbazioa `kv` mapetan.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test_list.rg` suite automatizatuaren bidez.
