# Capítulo 10: A lib `ini` — Ficheiros `.ini` por Seccións, `.env` e Interpolación de Variables

## 1. Por que existe a lib `ini`?

Sexamos sinceros: os ficheiros `.env` e `.ini` parecen triviais ata que alguén engade `export KEY="valor # con cancelo"`, comentarios `;` ao final da liña ou referencias cruzadas entre variables.

A lib **`ini`** analiza configuracións `.ini` con seccións (`[database]`) e ficheiros `.env` con prefixos `export`, preservando símbolos `#` e `;` dentro de comiñas e resolvendo interpolacións de variables en `dotenv parse`.

---

## 2. Artefactos, importación e arquitectura sen `libc`

En `ridgun-libs`, **`ini`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/ini.rg` (dominio `INI`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/ini.rglib` | Distribución e importación directa con `import ini` |
| **Ficheiro compilado** | `target/ini.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libini.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import ini` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

---

## 3. Referencia rápida da API de `ini`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `ini parse / ini stringify` | Analiza texto `.ini` por seccións en `IniDoc` e serialízao de volta |
| `ini get / ini get int / ini get bool / ini set` | Consultas tipadas por sección+chave (`""` para sección global) e actualización inmutable |
| `ini sections / ini section map` | Lista os nomes de sección ou extrae o mapa `[String String]` dunha sección |
| `dotenv parse` | Analiza ficheiros `.env` (`export K=V`, comiñas, comentarios e expansión de variables) |

---

## 4. Receitas prácticas en estilo tabular

### Receita 1: Fluxo principal con `ini`

Observa como os signos `=` e os pasos de transformación quedan aliñados coma unha táboa limpa:

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

### Receita 2: Composición segura e sen efectos laterais

Toda función da lib `ini` é compoñible co resto das 32 libs de `ridgun-libs`:

```ridgun
import ini

fn :: actualizar puerto (doc : IniDoc) (nuevo : String) => String
      actualizar puerto doc nuevo =
        doc2 = ini set doc "database" "port" nuevo
        ini stringify doc2
```

---

## 5. Baixo o capó: rendemento, memoria RMM e garantías

- **Garantía algorítmica e de seguridade**: Respecto total polos caracteres `#` e `;` cando aparecen entre comiñas simples ou dobres, e conversión booleana flexible (`true/1/yes/on` vs `false/0/no/off`).
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test_ini.rg`.
