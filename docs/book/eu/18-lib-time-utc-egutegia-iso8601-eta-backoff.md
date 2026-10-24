# 18. kapitulua: `time` lib-a — UTC Egutegi Zibila (Hinnant), ISO-8601, Iraupenak eta Backoff-a

## 1. Zergatik existitzen da `time` lib-a?

Izan gaitezen zintzoak: `libc`-ko data-funtzioak (`localtime`, `gmtime`, `mktime`) egoera global aldakorraren (`TZ`) menpe daude, ez dira hari-seguruak eta huts egiten dute 1900 vs 2000 bezalako bisurte-arauetan.

**`time`** lib-ak **Howard Hinnanten $O(1)$** egutegi zibil gregoriano proleptikoaren algoritmoa, **ISO-8601 / RFC 3339** (`YYYY-MM-DDTHH:MM:SSZ`) formateatze eta analisi zorrotza, iraupen irakurgarriak (`1h 1m 1s 5ms`) eta sare-berriro saiatzeetarako *exponential backoff* kalkulua inplementatzen ditu.

---

## 2. Artefaktuak, inportazioa eta `libc` gabeko arkitektura

`ridgun-libs`-en, **`time`** lehen mailako **lib** bat da, `src/main/ridgun/lib/time.rg` bidean kokatua (`TIME` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/time.rglib` | Banaketa eta inportazio zuzena `import time` bidez |
| **Fitxategi konpilatua** | `target/time.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libtime.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import time` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

---

## 3. `time` APIaren erreferentzia azkarra

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `time epoch to utc / time utc to epoch` | $O(1)$ bihurketa Unix epoch segundoen eta `(year, month, day, hour, min, sec)` artean |
| `time is leap year / time days in month / time day of week` | Bisurte-arauak (`400 / 100 / 4`), hileko egunak eta ISO asteguna (`1=Ast..7=Iga`) |
| `time format iso8601 / time parse iso8601` | `YYYY-MM-DDTHH:MM:SSZ` datak formateatu eta baliozkotzen ditu (`-1` otsailak 30 bezalakoetan) |
| `time format duration ms / time backoff ms` | Iraupen irakurgarriak eta $base \cdot 2^{attempt}$ atzerapen esponentzial mugatuak |

---

## 4. Errezeta praktikoak estilo taularatuan

### 1. errezeta: Fluxu nagusia `time` erabiliz

Ikusi nola `=` ikurrak eta eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren:

```ridgun
import time

fn :: registrar evento temporal (epoch_s : Int) => (String, Int, String)
      registrar evento temporal epoch_s =
        iso = time format iso8601 epoch_s
        sem = time day of week epoch_s
        dur = time format duration ms 3661005
        (iso, sem, dur)
```

### 2. errezeta: Konposizio segurua eta albo-ondoriorik gabea

`time` lib-eko funtzio oro `ridgun-libs`-eko gainerako 32 lib-ekin konposa daiteke:

```ridgun
import time

fn :: planificar reintentos () => [Int]
      planificar reintentos =
        [time backoff ms 0 100 5000, time backoff ms 1 100 5000, time backoff ms 2 100 5000, time backoff ms 9 100 5000]
```

---

## 5. Kaputaren azpian: errendimendua, RMM memoria eta bermeak

- **Berme algoritmikoa eta segurtasunekoa**: $O(1)$ egutegi-bihurketa urtez urteko begiztarik gabe eta hileko egunen baliozkotze zorrotza (bisurte ez diren urteetako otsailaren 29a ukatuz).
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test_time.rg` suite automatizatuaren bidez.
