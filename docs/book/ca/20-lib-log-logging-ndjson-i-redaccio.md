# Capítol 20: La lib `log` — Logging Estructurat NDJSON i Redacció Automàtica de Secrets

## 1. Per què existeix la lib `log`?

Siguem sincers: bolcar els camps d'una petició en un fitxer de log i descobrir setmanes després que acabes de desar `password`, `api_key` o `authorization` en text pla al teu agregador de logs és un incident de seguretat clàssic.

La lib **`log`** proporciona filtratge per severitat (`DEBUG`, `INFO`, `WARN`, `ERROR`), formatat en text humà i **NDJSON estructurat**, i **redacció automàtica de claus sensibles** (`password`, `secret`, `token`, `api_key`, `authorization`, `cookie`, `private_key` $\rightarrow$ `"[REDACTED]"`, mitigant `VUL-LOG-001`).

---

## 2. Artefactes, importació i arquitectura sense `libc`

A `ridgun-libs`, **`log`** és una **lib** de primera classe situada a `src/main/ridgun/lib/log.rg` (domini `LOG`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/log.rglib` | Distribució i importació directa amb `import log` |
| **Fitxer compilat** | `target/log.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/liblog.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Per fer servir aquesta lib en qualsevol fitxer `.rg`, n'hi ha prou de declarar `import log` a la capçalera i cridar les seves funcions amb espais o guions baixos indistintament.

---

## 3. Referència ràpida de l'API de `log`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `log level rank / log should emit` | Compara nivells (`DEBUG=10`, `INFO=20`, `WARN=30`, `ERROR=40`) enfront del llindar actiu |
| `log is sensitive key / log redact fields` | Substitueix valors de claus secretes per `"[REDACTED]"` sense importar majúscules |
| `log format text / log format json` | Formata línies text `clau=valor` o NDJSON RFC 8259 amb redacció automàtica de secrets |

---

## 4. Receptes pràctiques en estil tabular

### Recepta 1: Flux principal amb `log`

Observa com els signes `=` i els passos de transformació queden alineats com una taula neta:

```ridgun
import log

fn :: auditar login (usuario : String) (clave : String) => String
      auditar login usuario clave =
        campos = [("user", usuario), ("password", clave), ("ip", "10.0.0.1")]
        log format json "INFO" "intento de acceso" campos
```

### Recepta 2: Composició segura i sense efectes laterals

Tota funció de la lib `log` és componible amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import log

fn :: emitir si procede (umbral : String) (nivel : String) (msg : String) => String
      emitir si procede umbral nivel msg =
        | log should emit umbral nivel = log format text nivel msg [("service", "solstice")]
        | otherwise                    = ""
```

---

## 5. Sota el capó: rendiment, memòria RMM i garanties

- **Garantia algorísmica i de seguretat**: Tant `log format text` com `log format json` passen sempre els camps per `log redact fields` abans de serialitzar, garantint que cap secret es filtri per oblit.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test_log.rg`.
