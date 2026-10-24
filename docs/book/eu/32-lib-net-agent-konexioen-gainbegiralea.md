# 32. kapitulua: `net_agent` lib-a — Sare-konexioen Gainbegiralea eta Gertaera-zubi Ez-blokeatzailea

## 1. Zergatik existitzen da `net_agent` lib-a?

Izan gaitezen zintzoak: **Solstice** bezalako benetako zerbitzari batean, TCP konexioak onartzea zati erraza da; zailena aldi bereko bezeroen gehienekoa mugatzea, bezero zonbi geldoak deskonektatzea (*idle timeout*) eta `ppoll` begizta zure aktoreekin deskribatzaile-ihesik gabe lotzea da.

**`net_agent`** lib-ak `ridgun-libs`-en zirkulua ixten du **`posix`**, **`socket`** eta **`agent`** batuz: gainbegiratutako konexio-taulak (`NetSupervisor`) kudeatzen ditu, konkurrentzia-mugak (`max_conns`) aplikatzen ditu, konexio geldoak garbitzen ditu (`net evict idle`) eta nukleoko deskribatzaileen gertaerak gertaera tipatuetan (`NetEvReadyRead`, `NetEvReadyWrite`, `NetEvTimeout`, `NetEvError`) bihurtzen ditu, muturretik muturrerako TCP oihartzun-urrats oso batez (`net tcp echo step`) gain.

---

## 2. Artefaktuak, inportazioa eta `libc` gabeko arkitektura

`ridgun-libs`-en, **`net_agent`** lehen mailako **lib** bat da, `src/main/ridgun/lib/net_agent.rg` bidean kokatua (`AGENT` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/net_agent.rglib` | Banaketa eta inportazio zuzena `import net_agent` bidez |
| **Fitxategi konpilatua** | `target/net_agent.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libnet_agent.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import net_agent` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

---

## 3. `net_agent` APIaren erreferentzia azkarra

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `net supervisor new : Int -> Int -> NetSupervisor` | `max_conns` muga eta `idle_timeout_ms` geldotasun-epemuga dituen konexio-gainbegiralea sortzen du |
| `net register conn / net record rx / net record tx / net close conn` | Onartutako socketak erregistratu, byte/jarduera kontagailuak eguneratu eta parekoak ixten ditu |
| `net evict idle : NetSupervisor -> Int -> (NetSupervisor, [Int])` | `idle_timeout_ms` baino gehiago geldirik dauden konexioak itxi eta kanporatzen ditu, FDak itzuliz |
| `net poll fd : Int -> Bool -> Int -> NetEvent` | `NetEvReadyRead`, `NetEvReadyWrite`, `NetEvTimeout` edo `NetEvError` igortzen duen `wait fd` zubia |
| `net tcp echo step : String -> Int -> (Int, String)` | Muturretik muturrerako TCP loopback urrats osoa (`listen/connect/accept/supervise/echo`) |

---

## 4. Errezeta praktikoak estilo taularatuan

### 1. errezeta: Fluxu nagusia `net_agent` erabiliz

Ikusi nola `=` ikurrak eta eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren:

```ridgun
import net_agent

fn :: supervisar clientes () => (Int, [Int])
      supervisar clientes =
        s0        = net supervisor new 100 5000
        (s1, _)   = net register conn s0 10 "10.0.0.1" 51000 1000
        (s2, _)   = net register conn s1 11 "10.0.0.2" 51001 6500
        (s3, exp) = net evict idle s2 7000
        (net active count s3, exp)
```

### 2. errezeta: Konposizio segurua eta albo-ondoriorik gabea

`net_agent` lib-eko funtzio oro `ridgun-libs`-eko gainerako 32 lib-ekin konposa daiteke:

```ridgun
import net_agent

fn :: probar puente tcp supervisado () => (Int, String)
      probar puente tcp supervisado =
        net tcp echo step "ping-supervisado" 1000
```

---

## 5. Kaputaren azpian: errendimendua, RMM memoria eta bermeak

- **Berme algoritmikoa eta segurtasunekoa**: Deskribatzaileen agorpenaren aurkako babes automatikoa (`max_conns`), konexio geldoen kanporatze determinista eta socketen itxiera bermatua `net tcp echo step`-en.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test_net_agent.rg` suite automatizatuaren bidez.
