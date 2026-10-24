# 16. kapitulua: `cli` lib-a — Banderak, Aukerak, `--` Hesia, Azpikomandoak eta Ingurune-aldagaiak

## 1. Zergatik existitzen da `cli` lib-a?

Izan gaitezen zintzoak: `argv` eskuz analizatzea begizta xalo batekin hasten da beti, eta apurtzen amaitzen du norbaitek `-la` elkartuta, `--port=9090` berdin ikurrarekin edo `--` eta jarraian marratxoz hasten den `-fitxategia.rg` bat pasatzen duenean.

**`cli`** lib-ak bandera luzeak (`--verbose`), laburrak (`-v`), elkartuak (`-la`), baliodun aukerak (`--port=8080`, `--port 8080`, `-p 8080`), POSIX `--` bereizlea, argumentu posizionalak, azpikomandoak eta ingurune-aldagaien irakurketa tipatua ebazten ditu.

---

## 2. Artefaktuak, inportazioa eta `libc` gabeko arkitektura

`ridgun-libs`-en, **`cli`** lehen mailako **lib** bat da, `src/main/ridgun/lib/cli.rg` bidean kokatua (`CLI` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/cli.rglib` | Banaketa eta inportazio zuzena `import cli` bidez |
| **Fitxategi konpilatua** | `target/cli.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libcli.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import cli` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

---

## 3. `cli` APIaren erreferentzia azkarra

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `cli has flag : [String] -> String -> String -> Bool` | `--` aurretik `--long`, `-s` edo `-xyz` bandera elkartuak detektatzen ditu |
| `cli get opt / cli get int opt` | Testuzko edo zenbaki osozko aukera (`--k=v`, `--k v`, `-k v`) erauzten du lehenetsitako balioarekin |
| `cli positionals / cli subcommand` | Argumentu posizionalak biltzen ditu (`--` ondorengo guztia barne) |
| `env get or / env get int or / env get bool or` | Ingurune-aldagaiak irakurtzen ditu bihurketa tipatu eta ordezko balioekin |

---

## 4. Errezeta praktikoak estilo taularatuan

### 1. errezeta: Fluxu nagusia `cli` erabiliz

Ikusi nola `=` ikurrak eta eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren:

```ridgun
import cli

fn :: analizar comando (args : [String]) => (String, Bool, Int, [String])
      analizar comando args =
        sub   = cli subcommand args
        all_f = cli has flag args "--all" "-a"
        port  = cli get int opt args "--port" "-p" 8080
        arch  = cli positionals args ["--port", "-p"]
        (sub, all_f, port, arch)
```

### 2. errezeta: Konposizio segurua eta albo-ondoriorik gabea

`cli` lib-eko funtzio oro `ridgun-libs`-eko gainerako 32 lib-ekin konposa daiteke:

```ridgun
import cli

fn :: leer config entorno () => (Int, Bool)
      leer config entorno =
        workers = env get int or "SOLSTICE_WORKERS" 4
        debug   = env get bool or "SOLSTICE_DEBUG" False
        (workers, debug)
```

---

## 5. Kaputaren azpian: errendimendua, RMM memoria eta bermeak

- **Berme algoritmikoa eta segurtasunekoa**: POSIX `--` bereizlearen errespetu zorrotza: `--`-ren eskuinean dagoen inongo argumenturik ez da inoiz banderatzat hartzen.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test_cli.rg` suite automatizatuaren bidez.
