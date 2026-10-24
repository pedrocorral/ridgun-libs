# Capítulo 10: La lib `ini` — Archivos `.ini` por Secciones, `.env` e Interpolación de Variables

## 1. ¿Por qué existe la lib `ini`?

Seamos sinceros: los archivos `.env` y `.ini` parecen triviales hasta que alguien añade `export KEY="valor # con almohadilla"`, comentarios `;` al final de la línea o referencias cruzadas entre variables.

La lib **`ini`** analiza configuraciones `.ini` con secciones (`[database]`) y archivos `.env` con prefijos `export`, preservando símbolos `#` y `;` dentro de comillas y resolviendo interpolaciones de variables en `dotenv parse`.

---

## 2. Artefactos, importación y arquitectura sin `libc`

En `ridgun-libs`, **`ini`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/ini.rg` (dominio `INI`). Al compilar con `stable bundle`, se empaqueta en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/ini.rglib` | Distribución e importación directa con `import ini` |
| **Archivo compilado** | `target/ini.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libini.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import ini` en el encabezado y llamar a sus funciones con espacios o guiones bajos indistintamente.

---

## 3. Referencia rápida de la API de `ini`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `ini parse / ini stringify` | Analiza texto `.ini` por secciones en `IniDoc` y lo serializa de vuelta |
| `ini get / ini get int / ini get bool / ini set` | Consultas tipadas por sección+clave (`""` para sección global) y actualización inmutable |
| `ini sections / ini section map` | Lista los nombres de sección o extrae el mapa `[String String]` de una sección |
| `dotenv parse` | Analiza archivos `.env` (`export K=V`, comillas, comentarios y expansión de variables) |

---

## 4. Recetas prácticas en estilo tabular

### Receta 1: Flujo principal con `ini`

Observa cómo los signos `=` y los pasos de transformación quedan alineados como una tabla limpia:

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

### Receta 2: Composición segura y sin efectos laterales

Toda función de la lib `ini` es componible con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import ini

fn :: actualizar puerto (doc : IniDoc) (nuevo : String) => String
      actualizar puerto doc nuevo =
        doc2 = ini set doc "database" "port" nuevo
        ini stringify doc2
```

---

## 5. Bajo el capó: rendimiento, memoria RMM y garantías

- **Garantía algorítmica y de seguridad**: Respeto total por los caracteres `#` y `;` cuando aparecen entre comillas simples o dobles, y conversión booleana flexible (`true/1/yes/on` vs `false/0/no/off`).
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test_ini.rg`.
