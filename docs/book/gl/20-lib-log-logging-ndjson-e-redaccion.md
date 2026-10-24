# Capítulo 20: A lib `log` — Logging Estruturado NDJSON e Redacción Automática de Segredos

## 1. Por que existe a lib `log`?

Sexamos sinceros: envorcar os campos dunha petición nun ficheiro de log e descubrir semanas despois que acabas de gardar `password`, `api_key` ou `authorization` en texto plano no teu agregador de logs é un incidente de seguridade clásico.

A lib **`log`** proporciona filtrado por severidade (`DEBUG`, `INFO`, `WARN`, `ERROR`), formatado en texto humano e **NDJSON estruturado**, e **redacción automática de chaves sensibles** (`password`, `secret`, `token`, `api_key`, `authorization`, `cookie`, `private_key` $\rightarrow$ `"[REDACTED]"`, mitigando `VUL-LOG-001`).

---

## 2. Artefactos, importación e arquitectura sen `libc`

En `ridgun-libs`, **`log`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/log.rg` (dominio `LOG`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/log.rglib` | Distribución e importación directa con `import log` |
| **Ficheiro compilado** | `target/log.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/liblog.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import log` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

---

## 3. Referencia rápida da API de `log`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `log level rank / log should emit` | Compara niveis (`DEBUG=10`, `INFO=20`, `WARN=30`, `ERROR=40`) fronte ao limiar activo |
| `log is sensitive key / log redact fields` | Substitúe valores de chaves segredas por `"[REDACTED]"` sen importar maiúsculas |
| `log format text / log format json` | Formatea liñas texto `chave=valor` ou NDJSON RFC 8259 con redacción automática de segredos |

---

## 4. Receitas prácticas en estilo tabular

### Receita 1: Fluxo principal con `log`

Observa como os signos `=` e os pasos de transformación quedan aliñados coma unha táboa limpa:

```ridgun
import log

fn :: auditar login (usuario : String) (clave : String) => String
      auditar login usuario clave =
        campos = [("user", usuario), ("password", clave), ("ip", "10.0.0.1")]
        log format json "INFO" "intento de acceso" campos
```

### Receita 2: Composición segura e sen efectos laterais

Toda función da lib `log` é compoñible co resto das 32 libs de `ridgun-libs`:

```ridgun
import log

fn :: emitir si procede (umbral : String) (nivel : String) (msg : String) => String
      emitir si procede umbral nivel msg =
        | log should emit umbral nivel = log format text nivel msg [("service", "solstice")]
        | otherwise                    = ""
```

---

## 5. Baixo o capó: rendemento, memoria RMM e garantías

- **Garantía algorítmica e de seguridade**: Tanto `log format text` coma `log format json` pasan sempre os campos por `log redact fields` antes de serializar, garantindo que ningún segredo se filtre por esquecemento.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test_log.rg`.
