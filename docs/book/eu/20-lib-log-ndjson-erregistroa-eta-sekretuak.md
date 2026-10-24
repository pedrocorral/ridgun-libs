# 20. kapitulua: `log` lib-a — NDJSON Erregistro Egituratua eta Sekretuen Ezkutatze Automatikoa

## 1. Zergatik existitzen da `log` lib-a?

Izan gaitezen zintzoak: eskaera bateko eremuak log fitxategi batera irauli eta aste batzuk geroago `password`, `api_key` edo `authorization` testu lauan gorde dituzula deskubritzea segurtasun-gertakari klasiko bat da.

**`log`** lib-ak larritasunaren araberako iragazketa (`DEBUG`, `INFO`, `WARN`, `ERROR`), giza testuko eta **NDJSON egituratuko** formateatzea, eta **gako sentikorren ezkutatze automatikoa** (`password`, `secret`, `token`, `api_key`, `authorization`, `cookie`, `private_key` $\rightarrow$ `"[REDACTED]"`, `VUL-LOG-001` arinduz) eskaintzen ditu.

---

## 2. Artefaktuak, inportazioa eta `libc` gabeko arkitektura

`ridgun-libs`-en, **`log`** lehen mailako **lib** bat da, `src/main/ridgun/lib/log.rg` bidean kokatua (`LOG` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/log.rglib` | Banaketa eta inportazio zuzena `import log` bidez |
| **Fitxategi konpilatua** | `target/log.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/liblog.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import log` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

---

## 3. `log` APIaren erreferentzia azkarra

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `log level rank / log should emit` | Log mailak (`DEBUG=10`, `INFO=20`, `WARN=30`, `ERROR=40`) atalase aktiboarekin konparatzen ditu |
| `log is sensitive key / log redact fields` | Gako sekretuen balioak `"[REDACTED]"`-ekin ordezkatzen ditu letra larri/xeheak kontuan hartu gabe |
| `log format text / log format json` | `gako=balio` testu-lerroak edo RFC 8259 NDJSON formateatzen ditu sekretuen ezkutatze automatikoarekin |

---

## 4. Errezeta praktikoak estilo taularatuan

### 1. errezeta: Fluxu nagusia `log` erabiliz

Ikusi nola `=` ikurrak eta eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren:

```ridgun
import log

fn :: auditar login (usuario : String) (clave : String) => String
      auditar login usuario clave =
        campos = [("user", usuario), ("password", clave), ("ip", "10.0.0.1")]
        log format json "INFO" "intento de acceso" campos
```

### 2. errezeta: Konposizio segurua eta albo-ondoriorik gabea

`log` lib-eko funtzio oro `ridgun-libs`-eko gainerako 32 lib-ekin konposa daiteke:

```ridgun
import log

fn :: emitir si procede (umbral : String) (nivel : String) (msg : String) => String
      emitir si procede umbral nivel msg =
        | log should emit umbral nivel = log format text nivel msg [("service", "solstice")]
        | otherwise                    = ""
```

---

## 5. Kaputaren azpian: errendimendua, RMM memoria eta bermeak

- **Berme algoritmikoa eta segurtasunekoa**: Bai `log format text`-ek eta bai `log format json`-ek eremuak `log redact fields`-etik pasatzen dituzte beti serializatu aurretik, inongo sekreturik ahaztuta ez isurtzea bermatuz.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test_log.rg` suite automatizatuaren bidez.
