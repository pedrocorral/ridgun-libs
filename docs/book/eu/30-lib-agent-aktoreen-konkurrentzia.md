# 30. kapitulua: `agent` lib-a — Aktoreen Eredu Natiboa (`agent`, `send`, `receive`), KV Biltegia eta Rate Limiter-a

## 1. Zergatik existitzen da `agent` lib-a?

Izan gaitezen zintzoak: harien artean memoria aldakorra `Mutex`, `RwLock` eta baldintza-aldagaiekin partekatzea *deadlock* eta lasterketa-baldintzen fabrika agortezina da.

**`agent`** lib-ak Ridgunen **Agenteen Eredu Natiboa** (`agent`, `send ... to`, `receive from`, `try receive from`, `stop`) baliatzen du Copy-on-Write mezu-igorpenezko postontzi isolatuak, gako-balio biltegi konkurrente bat (`KvStore`), token-ontzi bidezko tasa-mugatzaile bat (`RateBucket`) eta egoera-gainbegiratzea (`AgentHealth`) eskaintzeko.

---

## 2. Artefaktuak, inportazioa eta `libc` gabeko arkitektura

`ridgun-libs`-en, **`agent`** lehen mailako **lib** bat da, `src/main/ridgun/lib/agent.rg` bidean kokatua (`AGENT` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/agent.rglib` | Banaketa eta inportazio zuzena `import agent` bidez |
| **Fitxategi konpilatua** | `target/agent.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libagent.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import agent` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

---

## 3. `agent` APIaren erreferentzia azkarra

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `agent roundtrip / agent drain count` | Aktore natiboak (`agent`) abiarazi, mezuak trukatu (`send ... to` / `receive from`) eta `stop` egiten du |
| `kv store new / kv store apply` | Aktoreentzako gako-balio biltegi aldaezina (`KvPut`, `KvGet`, `KvDelete`, `KvClear`) |
| `rate bucket new / rate bucket allow` | Token-ontzi bidezko tasa-mugatzailea, ontzi eguneratua eta `(allowed, remaining)` itzultzen dituena |
| `sup mark failed / sup should restart` | Berrabiarazte-aurrekontua (`max_restarts`) kontrolatzen duten gainbegiratze-politikak |

---

## 4. Errezeta praktikoak estilo taularatuan

### 1. errezeta: Fluxu nagusia `agent` erabiliz

Ikusi nola `=` ikurrak eta eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren:

```ridgun
import agent

fn :: probar actor nativo () => (Int, Int)
      probar actor nativo =
        eco = agent roundtrip 42
        vac = agent drain count [10, 20, 30]
        (eco, vac)
```

### 2. errezeta: Konposizio segurua eta albo-ondoriorik gabea

`agent` lib-eko funtzio oro `ridgun-libs`-eko gainerako 32 lib-ekin konposa daiteke:

```ridgun
import agent

fn :: aplicar limite peticion () => (Bool, Int)
      aplicar limite peticion =
        b0         = rate bucket new 10 2 1000
        (b1, res1) = rate bucket allow b0 1 1000
        rateresp allowed res1, rateobs remaining res1
```

---

## 5. Kaputaren azpian: errendimendua, RMM memoria eta bermeak

- **Berme algoritmikoa eta segurtasunekoa**: Zero memoria aldakor partekatu aktoreen artean: mezu bakoitza balioz / Copy-on-Write bidez transferitzen da eta `stop`-ek agentearen eskualdea modu deterministan askatzen du.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test_agent.rg` suite automatizatuaren bidez.
