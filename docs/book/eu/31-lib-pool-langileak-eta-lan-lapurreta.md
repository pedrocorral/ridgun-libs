# 31. kapitulua: `pool` lib-a — Langileen Pool Mugatua, Round-Robin eta Lan-lapurreta

## 1. Zergatik existitzen da `pool` lib-a?

Izan gaitezen zintzoak: sartzen den eskaera bakoitzeko goi-mugarik gabe hari edo aktore berri bat abiarazteak (`unbounded spawning`) trafiko-gailur batean memoria segundo gutxitan agortzea eragiten du (*Out Of Memory*).

**`pool`** lib-ak **kontrapresio esplizituko** ataza-banatzaile bat (`PoolAccept`, `PoolRejectFull`), sorten $K$ erreietako partizio orekatua (`pool partition`), **lan-lapurreta (*work-stealing*)** bidezko berrorekatzea (`pool steal rebalance`) eta aktore natiboen gaineko exekuzio paraleloa eskaintzen ditu.

---

## 2. Artefaktuak, inportazioa eta `libc` gabeko arkitektura

`ridgun-libs`-en, **`pool`** lehen mailako **lib** bat da, `src/main/ridgun/lib/pool.rg` bidean kokatua (`AGENT` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/pool.rglib` | Banaketa eta inportazio zuzena `import pool` bidez |
| **Fitxategi konpilatua** | `target/pool.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libpool.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import pool` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

---

## 3. `pool` APIaren erreferentzia azkarra

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `pool new : Int -> Int -> PoolState` | `workers` errei eta `max_queue` gehienezko edukiera dituen pool mugatua sortzen du |
| `pool submit : PoolState -> PoolTask -> (PoolState, PoolDecision)` | Ataza bat round-robin bidez ilaran jartzen du edo `PoolRejectFull` itzultzen du beteta badago |
| `pool partition / pool steal rebalance` | Sortak $K$ langileren artean banatu eta gainkargatutako ilara baten erdia lapurtzen du langile libre batentzat |
| `pool map sum / pool parallel sum2` | Lan-kargak paraleloan banatzen ditu `agent` langile natiboen artean |

---

## 4. Errezeta praktikoak estilo taularatuan

### 1. errezeta: Fluxu nagusia `pool` erabiliz

Ikusi nola `=` ikurrak eta eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren:

```ridgun
import pool

fn :: encolar con contrapresion () => (Int, Int)
      encolar con contrapresion =
        p0        = pool new 4 16
        tarea     = PoolTask 1 100 "indexar-bloque"
        (p1, dec) = pool submit p0 tarea
        (pool queued p1, pool accepted p1)
```

### 2. errezeta: Konposizio segurua eta albo-ondoriorik gabea

`pool` lib-eko funtzio oro `ridgun-libs`-eko gainerako 32 lib-ekin konposa daiteke:

```ridgun
import pool

fn :: sumar en paralelo () => Int
      sumar en paralelo =
        pool parallel sum2 [10, 20, 30] [40, 50, 60]
```

---

## 5. Kaputaren azpian: errendimendua, RMM memoria eta bermeak

- **Berme algoritmikoa eta segurtasunekoa**: Ilara-edukiera zorrozki mugatua (`queued <= max_queue`) gainkargapean memoria babesteko eta langileen arteko banaketa determinista.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test_pool.rg` suite automatizatuaren bidez.
