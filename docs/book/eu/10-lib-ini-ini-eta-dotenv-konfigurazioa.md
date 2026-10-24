# 10. kapitulua: `ini` lib-a — Atalkako `.ini` Fitxategiak, `.env` eta Aldagaien Interpolazioa

## 1. Zergatik existitzen da `ini` lib-a?

Izan gaitezen zintzoak: `.env` eta `.ini` fitxategiak hutsalkeriak dirudite norbaitek `export KEY="balioa # traolarekin"`, lerro amaierako `;` iruzkinak edo aldagaien arteko erreferentzia gurutzatuak gehitzen dituen arte.

**`ini`** lib-ak ataldun `.ini` konfigurazioak (`[database]`) eta `export` aurrizkidun `.env` fitxategiak analizatzen ditu, komatxo barruko `#` eta `;` ikurrak mantenduz eta `dotenv parse`-n aldagaien interpolazioak ebatziz.

---

## 2. Artefaktuak, inportazioa eta `libc` gabeko arkitektura

`ridgun-libs`-en, **`ini`** lehen mailako **lib** bat da, `src/main/ridgun/lib/ini.rg` bidean kokatua (`INI` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/ini.rglib` | Banaketa eta inportazio zuzena `import ini` bidez |
| **Fitxategi konpilatua** | `target/ini.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libini.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import ini` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

---

## 3. `ini` APIaren erreferentzia azkarra

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `ini parse / ini stringify` | Atalkako `.ini` testua `IniDoc`-era analizatzen du eta testu kanonikora serializatzen du |
| `ini get / ini get int / ini get bool / ini set` | Atal+gako bidezko kontsulta tipatuak (`""` atal globalerako) eta eguneratze aldaezina |
| `ini sections / ini section map` | Atal-izen guztiak zerrendatzen ditu edo atal baten `[String String]` mapa erauzten du |
| `dotenv parse` | `.env` lerroak analizatzen ditu (`export K=V`, komatxoak, iruzkinak eta aldagaien hedapena) |

---

## 4. Errezeta praktikoak estilo taularatuan

### 1. errezeta: Fluxu nagusia `ini` erabiliz

Ikusi nola `=` ikurrak eta eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren:

```ridgun
import ini

fn :: cargar base de datos (texto_ini : String) => (String, Int, Bool)
      cargar base de datos texto_ini =
        doc  = ini parse texto_ini
        host = ini get doc "database" "host" "localhost"
        port = ini get int doc "database" "port" 5432
        pool = ini get bool doc "database" "pool" True
        (host, port, pool)
```

### 2. errezeta: Konposizio segurua eta albo-ondoriorik gabea

`ini` lib-eko funtzio oro `ridgun-libs`-eko gainerako 32 lib-ekin konposa daiteke:

```ridgun
import ini

fn :: actualizar puerto (doc : IniDoc) (nuevo : String) => String
      actualizar puerto doc nuevo =
        doc2 = ini set doc "database" "port" nuevo
        ini stringify doc2
```

---

## 5. Kaputaren azpian: errendimendua, RMM memoria eta bermeak

- **Berme algoritmikoa eta segurtasunekoa**: Errespetu osoa `#` eta `;` karaktereekiko komatxo sinple edo bikoitzen artean agertzen direnean, eta bihurketa boolear malgua (`true/1/yes/on` vs `false/0/no/off`).
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test_ini.rg` suite automatizatuaren bidez.
