# 08. kapitulua: `json` lib-a — RFC 8259 AST Zuhaitz Errekurtsiboa, Pretty-Printer eta Bide-kontsultak

## 1. Zergatik existitzen da `json` lib-a?

Izan gaitezen zintzoak: lengoaia estatiko askotan JSON habiaratu batean nabigatzeak hiru pantaila kode errepikakor idaztea edo hamar `.and_then()` kateatzea eskatzen du ataka soil bat irakurri aurretik.

**`json`** lib-ak **RFC 8259**-rako jaitsiera errekurtsiboko analizatzaile oso bat eskaintzen du `JsonVal` ADT aljebraikoaren gainean (`JnNull`, `JnBool`, `JnInt`, `JnStr`, `JnArr`, `JnObj`, `JnErr`), serializazio trinkoa zein koskaduna (`json pretty`) eta puntu bidezko bide-kontsultak (`"server.http.port"`).

---

## 2. Artefaktuak, inportazioa eta `libc` gabeko arkitektura

`ridgun-libs`-en, **`json`** lehen mailako **lib** bat da, `src/main/ridgun/lib/json.rg` bidean kokatua (`JSON` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/json.rglib` | Banaketa eta inportazio zuzena `import json` bidez |
| **Fitxategi konpilatua** | `target/json.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libjson.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import json` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

---

## 3. `json` APIaren erreferentzia azkarra

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `type JsonVal` | `JnNull | JnBool Bool | JnInt Int | JnStr String | JnArr [JsonVal] | JnObj [String JsonVal] | JnErr String` |
| `json parse / json is ok` | JSON testua `JsonVal` zuhaitzean analizatzen du eta `JnErr` ez dagoela egiaztatu |
| `json stringify / json pretty` | `JsonVal` JSON trinko edo lerro anitzeko koskadunera serializatzen du |
| `json get path / json get str / json get int / json get bool` | Objektu eta zerrenda habiaratuak zeharkatzen ditu puntudun bideekin (`"a.b.0.c"`) |

---

## 4. Errezeta praktikoak estilo taularatuan

### 1. errezeta: Fluxu nagusia `json` erabiliz

Ikusi nola `=` ikurrak eta eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren:

```ridgun
import json

fn :: leer config servidor (raw : String) => (String, Int, Bool)
      leer config servidor raw =
        doc  = json parse raw
        host = json get str doc "server.host" "127.0.0.1"
        port = json get int doc "server.port" 8080
        tls  = json get bool doc "server.tls.enabled" False
        (host, port, tls)
```

### 2. errezeta: Konposizio segurua eta albo-ondoriorik gabea

`json` lib-eko funtzio oro `ridgun-libs`-eko gainerako 32 lib-ekin konposa daiteke:

```ridgun
import json

fn :: construir manifiesto () => String
      construir manifiesto =
        nodo = JnObj [("app", JnStr "solstice"), ("workers", JnInt 8), ("tags", JnArr [JnStr "elf64", JnStr "rmm2"])]
        json pretty nodo 2
```

---

## 5. Kaputaren azpian: errendimendua, RMM memoria eta bermeak

- **Berme algoritmikoa eta segurtasunekoa**: Erro-balioaren ondorengo zaborraren (`trailing garbage`) ukapen zorrotza, ihes-sekuentzien kudeaketa osoa eta salbuespenik gabeko `JnErr` itzulera segurua.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test_json.rg` suite automatizatuaren bidez.
