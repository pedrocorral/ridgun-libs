# Capítulo 20: La lib `log` — Logging Estructurado NDJSON y Redacción Automática de Secretos

## 1. ¿Por qué existe la lib `log`?

Seamos sinceros: volcar los campos de una petición en un archivo de log y descubrir semanas después que acabas de guardar `password`, `api_key` o `authorization` en texto plano en tu agregador de logs es un incidente de seguridad clásico.

La lib **`log`** proporciona filtrado por severidad (`DEBUG`, `INFO`, `WARN`, `ERROR`), formateo en texto humano y **NDJSON estructurado**, y **redacción automática de claves sensibles** (`password`, `secret`, `token`, `api_key`, `authorization`, `cookie`, `private_key` $\rightarrow$ `"[REDACTED]"`, mitigando `VUL-LOG-001`).

---

## 2. Artefactos, importación y arquitectura sin `libc`

En `ridgun-libs`, **`log`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/log.rg` (dominio `LOG`). Al compilar con `stable bundle`, se empaqueta en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/log.rglib` | Distribución e importación directa con `import log` |
| **Archivo compilado** | `target/log.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/liblog.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import log` en el encabezado y llamar a sus funciones con espacios o guiones bajos indistintamente.

---

## 3. Referencia rápida de la API de `log`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `log level rank / log should emit` | Compara niveles (`DEBUG=10`, `INFO=20`, `WARN=30`, `ERROR=40`) frente al umbral activo |
| `log is sensitive key / log redact fields` | Sustituye valores de claves secretas por `"[REDACTED]"` sin importar mayúsculas |
| `log format text / log format json` | Formatea líneas texto `clave=valor` o NDJSON RFC 8259 con redacción automática de secretos |

---

## 4. Recetas prácticas en estilo tabular

### Receta 1: Flujo principal con `log`

Observa cómo los signos `=` y los pasos de transformación quedan alineados como una tabla limpia:

```ridgun
import log

fn :: auditar login (usuario : String) (clave : String) => String
      auditar login usuario clave =
        campos = [("user", usuario), ("password", clave), ("ip", "10.0.0.1")]
        log format json "INFO" "intento de acceso" campos
```

### Receta 2: Composición segura y sin efectos laterales

Toda función de la lib `log` es componible con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import log

fn :: emitir si procede (umbral : String) (nivel : String) (msg : String) => String
      emitir si procede umbral nivel msg =
        | log should emit umbral nivel = log format text nivel msg [("service", "solstice")]
        | otherwise                    = ""
```

---

## 5. Bajo el capó: rendimiento, memoria RMM y garantías

- **Garantía algorítmica y de seguridad**: Tanto `log format text` como `log format json` pasan siempre los campos por `log redact fields` antes de serializar, garantizando que ningún secreto se filtre por olvido.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test_log.rg`.
