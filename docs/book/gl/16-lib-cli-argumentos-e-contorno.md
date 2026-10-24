# Capítulo 16: A lib `cli` — Bandeiras, Opcións, Barreira `--`, Subcomandos e Variables de Contorno

## 1. Por que existe a lib `cli`?

Sexamos sinceros: analizar `argv` á man sempre comeza cun bucle inocente e acaba rompéndose cando alguén pasa `-la` agrupado, `--port=9090` con signo igual ou `--` seguido dun ficheiro que comeza por guión `-ficheiro.rg`.

A lib **`cli`** resolve bandeiras longas (`--verbose`), curtas (`-v`), agrupadas (`-la`), opcións con valor (`--port=8080`, `--port 8080`, `-p 8080`), o separador POSIX `--`, argumentos posicionais, subcomandos e lectura tipada de variables de contorno (`env get int or`, `env get bool or`).

---

## 2. Artefactos, importación e arquitectura sen `libc`

En `ridgun-libs`, **`cli`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/cli.rg` (dominio `CLI`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/cli.rglib` | Distribución e importación directa con `import cli` |
| **Ficheiro compilado** | `target/cli.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libcli.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import cli` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

---

## 3. Referencia rápida da API de `cli`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `cli has flag : [String] -> String -> String -> Bool` | Detecta `--long`, `-s` ou bandeiras agrupadas `-xyz` antes de `--` |
| `cli get opt / cli get int opt` | Extrae opción de texto ou enteira (`--k=v`, `--k v`, `-k v`) con valor por defecto |
| `cli positionals / cli subcommand` | Recolle os argumentos posicionais (incluíndo todo o que segue a `--`) |
| `env get or / env get int or / env get bool or` | Le variables de contorno con conversión tipada e valores de apoio |

---

## 4. Receitas prácticas en estilo tabular

### Receita 1: Fluxo principal con `cli`

Observa como os signos `=` e os pasos de transformación quedan aliñados coma unha táboa limpa:

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

### Receita 2: Composición segura e sen efectos laterais

Toda función da lib `cli` é compoñible co resto das 32 libs de `ridgun-libs`:

```ridgun
import cli

fn :: leer config entorno () => (Int, Bool)
      leer config entorno =
        workers = env get int or "SOLSTICE_WORKERS" 4
        debug   = env get bool or "SOLSTICE_DEBUG" False
        (workers, debug)
```

---

## 5. Baixo o capó: rendemento, memoria RMM e garantías

- **Garantía algorítmica e de seguridade**: Respecto estrito do separador POSIX `--`: ningún argumento situado á dereita de `--` se interpreta xamais como bandeira.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test_cli.rg`.
