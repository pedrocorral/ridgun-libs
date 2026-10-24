# 09. kapitulua: `csv` lib-a — CSV/TSV-rako RFC 4180 Egoera-analizatzailea eta Taula Indexatuak

## 1. Zergatik existitzen da `csv` lib-a?

Izan gaitezen zintzoak: mundu guztiak uste du CSV bat analizatzea `str split lerroa ","` egitea dela... harik eta komatxo artean koma bat, `""` komatxo iheskorrak edo gelaxka baten erdian `\r\n` lerro-jauzi bat dituen eremu bat agertzen den arte.

**`csv`** lib-ak **RFC 4180** arauarekiko egoera-makina oso bat inplementatzen du CSV eta TSV formatuetarako, komatxo adimentsudun serializazio automatikoa eta goiburu-izenaren araberako zutabeak eta errenkadak kontsultatzeko `CsvTable` mota.

---

## 2. Artefaktuak, inportazioa eta `libc` gabeko arkitektura

`ridgun-libs`-en, **`csv`** lehen mailako **lib** bat da, `src/main/ridgun/lib/csv.rg` bidean kokatua (`CSV` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/csv.rglib` | Banaketa eta inportazio zuzena `import csv` bidez |
| **Fitxategi konpilatua** | `target/csv.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libcsv.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import csv` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

---

## 3. `csv` APIaren erreferentzia azkarra

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `csv parse / tsv parse / csv parse with` | CSV/TSV testua (`""` ihesak eta lerro anitzeko gelaxkak barne) `[[String]]`-ra analizatzen du |
| `csv stringify / tsv stringify` | `[[String]]` serializatzen du, bereizleak, komatxoak edo jauziak dituzten gelaxkak soilik komatxo artean jarriz |
| `csv parse table / csv get cell / csv col` | Goiburuz indexatutako `CsvTable` kontsulta `(errenkada, zutabe_izena)` bidez edo zutabe osoa |
| `csv row to kv / csv table to kv list` | Errenkada taularatuak goiburuz indexatutako `[String String]` hiztegietara bihurtzen ditu |

---

## 4. Errezeta praktikoak estilo taularatuan

### 1. errezeta: Fluxu nagusia `csv` erabiliz

Ikusi nola `=` ikurrak eta eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren:

```ridgun
import csv

fn :: extraer columna precios (raw_csv : String) => ([String], String)
      extraer columna precios raw_csv =
        tabla   = csv parse table raw_csv
        precios = csv col tabla "precio"
        primero = csv get cell tabla 0 "producto" "desconocido"
        (precios, primero)
```

### 2. errezeta: Konposizio segurua eta albo-ondoriorik gabea

`csv` lib-eko funtzio oro `ridgun-libs`-eko gainerako 32 lib-ekin konposa daiteke:

```ridgun
import csv

fn :: exportar informe () => String
      exportar informe =
        filas = [["id", "nota"], ["1", "Contiene, coma"], ["2", "Dijo "hola""]]
        csv stringify filas
```

---

## 5. Kaputaren azpian: errendimendua, RMM memoria eta bermeak

- **Berme algoritmikoa eta segurtasunekoa**: `\r\n` eta `\n` lerro-jauzien euskarri zehatza komatxoen barruan zein kanpoan, eta zero datu-galera `csv parse (csv stringify errenkadak)` joan-etorrietan.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test_csv.rg` suite automatizatuaren bidez.
