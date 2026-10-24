# Capítulo 23: A lib `io` — Erros Tipados `IoResult`, E/S con `with timeout` e Procesos

## 1. Por que existe a lib `io`?

Sexamos sinceros: unha chamada a `read()` ou un subproceso fillo sen data límite (`timeout`) é unha invitación a que un só recurso colgado esgote todos os traballadores do teu servidor.

A lib **`io`** modela cada operación do sistema con ADTs explícitos (`IoError`, `IoResult[A]`), combina `ppoll` non bloqueante con cotas léxicas `with timeout wait_ms do` de Ridgun e ofrece os operadores mixfix `read fd ... timeout` e `write fd ... timeout`.

---

## 2. Artefactos, importación e arquitectura sen `libc`

En `ridgun-libs`, **`io`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/io.rg` (dominio `IO`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/io.rglib` | Distribución e importación directa con `import io` |
| **Ficheiro compilado** | `target/io.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libio.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import io` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

---

## 3. Referencia rápida da API de `io`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `type IoError / type IoResult[A]` | `IoNotFound | IoPermission | IoTimeout | IoRefused | IoReset | IoEOF | IoInvalid | IoSysError` |
| `io read with timeout / io write with timeout` | Lectura/escritura non bloqueante de descritor acoutada por `wait_ms` |
| `read fd N max M timeout T / write fd N data S timeout T` | Operadores mixfix ergonómicos (`op ::`) para E/S de descritor con data límite |
| `io read file / io write file / io read lines` | Funcións seguras de ficheiros e fluxos de liñas que devolven `IoResult` |
| `exec with timeout : String -> Int -> IoResult[ProcStatus]` | Executa un comando externo acoutado por unha cota léxica `with timeout` |

---

## 4. Receitas prácticas en estilo tabular

### Receita 1: Fluxo principal con `io`

Observa como os signos `=` e os pasos de transformación quedan aliñados coma unha táboa limpa:

```ridgun
import io

fn :: leer peticion segura (fd : Int) => String
      leer peticion segura fd =
        res = read fd fd max 4096 timeout 250
        io unwrap or res ""
```

### Receita 2: Composición segura e sen efectos laterais

Toda función da lib `io` é compoñible co resto das 32 libs de `ridgun-libs`:

```ridgun
import io

fn :: describir fallo () => String
      describir fallo =
        format io error (IoTimeout "read" 250)
```

---

## 5. Baixo o capó: rendemento, memoria RMM e garantías

- **Garantía algorítmica e de seguridade**: Ningunha lectura, escritura ou comando executado a través de `io` con cota `wait_ms` pode bloquear indefinidamente o fío ou actor chamante.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test_io.rg`.
