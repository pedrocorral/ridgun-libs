# 22. kapitulua: `posix` lib-a — Plataforma Abstrakzio Geruza (PAL), Erlojuak, Seinaleak eta CSPRNG

## 1. Zergatik existitzen da `posix` lib-a?

Izan gaitezen zintzoak: `O_CREAT`, `O_NONBLOCK` bezalako banderak edo syscall zenbakiak aldatu egiten dira Linux, macOS eta arkitekturen artean (`X86_64` vs `Arm64`), eta C-n dena `#ifdef` oihan irakurgaitz batekin konpontzen da.

**`posix`** lib-ak Ridgunen 2 mailako **Plataforma Abstrakzio Geruza (PAL)** inplementatzen du `sys os` (`Linux | MacOS | Windows`) eta `sys arch` (`X86_64 | Arm64 | RiscV64`) gaineko zain taularatuak erabiliz, deskribatzaileen zundaketaz (`wait fd`), erloju monotonoez (`RGF-017`), seinaleez (`RGF-018`) eta nukleoaren CSPRNG entropiaz (`sys random bytes`) gain.

---

## 2. Artefaktuak, inportazioa eta `libc` gabeko arkitektura

`ridgun-libs`-en, **`posix`** lehen mailako **lib** bat da, `src/main/ridgun/lib/posix.rg` bidean kokatua (`POSIX` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/posix.rglib` | Banaketa eta inportazio zuzena `import posix` bidez |
| **Fitxategi konpilatua** | `target/posix.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libposix.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import posix` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

---

## 3. `posix` APIaren erreferentzia azkarra

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `pal open create trunc wr / pal o nonblock` | SE banderen itzulpena `sys os`-en arabera (`Linux | MacOS | Windows`) |
| `wait fd : Int -> Int -> Int -> PollStatus` | Deskribatzaile bat zundatzen du `PollReady`, `PollTimeout` edo `PollError errno` itzuliz |
| `clock monotonic ms / clock monotonic ns / clock wall ms` | Erloju monotonoak eta UTC horma-erlojua milisegundotan (`RGF-017`) |
| `signal watch / signal poll / sys random bytes` | Seinaleen zundaketa ez-blokeatzailea (`SIGINT`, `SIGTERM`) eta nukleoaren CSPRNG byteak |
| `read text / write text / file exists / run cmd` | Goi-mailako fitxategi S/I, direktorio-eragiketak eta azpiprozesuen bilgarriak |

---

## 4. Errezeta praktikoak estilo taularatuan

### 1. errezeta: Fluxu nagusia `posix` erabiliz

Ikusi nola `=` ikurrak eta eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren:

```ridgun
import posix

fn :: medir operacion () => (Int, Int)
      medir operacion =
        t0  = clock monotonic ms
        rnd = len (sys random bytes 32)
        t1  = clock monotonic ms
        (rnd, t1 - t0)
```

### 2. errezeta: Konposizio segurua eta albo-ondoriorik gabea

`posix` lib-eko funtzio oro `ridgun-libs`-eko gainerako 32 lib-ekin konposa daiteke:

```ridgun
import posix

fn :: esperar lectura (fd : Int) => Bool
      esperar lectura fd =
        est = wait fd fd poll_in 100
        est == PollReady
```

---

## 5. Kaputaren azpian: errendimendua, RMM memoria eta bermeak

- **Berme algoritmikoa eta segurtasunekoa**: Helburuko bitarrari ez dagozkion `sys os` eta `sys arch` adarrak konpilazio-garaian ezabatzen ditu (Dead-Code Elimination) `ridgunc`-ek.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test_posix.rg` suite automatizatuaren bidez.
