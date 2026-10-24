# Capítulo 08: A lib `json` — Árbore AST Recursiva RFC 8259, Pretty-Printer e Consultas por Ruta

## 1. Por que existe a lib `json`?

Sexamos sinceros: navegar un JSON aniñado en moitas linguaxes estáticas implica escribir tres pantallas de boilerplate ou encadear dez `.and_then()` antes de ler un simple porto.

A lib **`json`** proporciona un analizador descendente recursivo completo para **RFC 8259** sobre o ADT alxébrico `JsonVal` (`JnNull`, `JnBool`, `JnInt`, `JnStr`, `JnArr`, `JnObj`, `JnErr`), serialización compacta e sangrada (`json pretty`) e consultas directas por ruta con puntos (`"server.http.port"`, `"users.0.name"`).

---

## 2. Artefactos, importación e arquitectura sen `libc`

En `ridgun-libs`, **`json`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/json.rg` (dominio `JSON`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/json.rglib` | Distribución e importación directa con `import json` |
| **Ficheiro compilado** | `target/json.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libjson.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import json` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

---

## 3. Referencia rápida da API de `json`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `type JsonVal` | `JnNull | JnBool Bool | JnInt Int | JnStr String | JnArr [JsonVal] | JnObj [String JsonVal] | JnErr String` |
| `json parse / json is ok` | Analiza texto JSON nunha árbore `JsonVal` e valida a ausencia de `JnErr` |
| `json stringify / json pretty` | Serializa `JsonVal` a JSON compacto ou multiliña sangrado |
| `json get path / json get str / json get int / json get bool` | Percorre obxectos e listas aniñados mediante rutas con puntos (`"a.b.0.c"`) |

---

## 4. Receitas prácticas en estilo tabular

### Receita 1: Fluxo principal con `json`

Observa como os signos `=` e os pasos de transformación quedan aliñados coma unha táboa limpa:

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

### Receita 2: Composición segura e sen efectos laterais

Toda función da lib `json` é compoñible co resto das 32 libs de `ridgun-libs`:

```ridgun
import json

fn :: construir manifiesto () => String
      construir manifiesto =
        nodo = JnObj [("app", JnStr "solstice"), ("workers", JnInt 8), ("tags", JnArr [JnStr "elf64", JnStr "rmm2"])]
        json pretty nodo 2
```

---

## 5. Baixo o capó: rendemento, memoria RMM e garantías

- **Garantía algorítmica e de seguridade**: Rexeitamento estrito de lixo sobrante tras o valor raíz (`trailing garbage`), manexo completo de escapes e retorno seguro de `JnErr` sen excepcións.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test_json.rg`.
