# Capítulo 14: La lib `template` — Plantillas Mustache Seguras con Auto-Escape HTML y LaTeX

## 1. ¿Por qué existe la lib `template`?

Seamos sinceros: montar páginas HTML o informes LaTeX concatenando cadenas a mano es la receta perfecta para una vulnerabilidad XSS (`<script>`) o para que un simple símbolo `%` o `_` rompa la compilación de tu PDF.

La lib **`template`** ofrece un motor **Mustache** sin lógica arbitraria con auto-escape contextual (`TmplPlain`, `TmplHtml`, `TmplLatex`), sustitución cruda explícita (`{{{raw}}}` / `{{&raw}}`), comentarios (`{{! ... }}`), secciones condicionales (`{{#sec}}...{{/sec}}`) e invertidas (`{{^sec}}...{{/sec}}`).

---

## 2. Artefactos, importación y arquitectura sin `libc`

En `ridgun-libs`, **`template`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/template.rg` (dominio `TMPL`). Al compilar con `stable bundle`, se empaqueta en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/template.rglib` | Distribución e importación directa con `import template` |
| **Archivo compilado** | `target/template.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libtemplate.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import template` en el encabezado y llamar a sus funciones con espacios o guiones bajos indistintamente.

---

## 3. Referencia rápida de la API de `template`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `tmpl render / tmpl render html / tmpl render latex` | Renderiza plantillas Mustache con auto-escape plano, HTML o LaTeX |
| `tmpl escape html / tmpl escape latex` | Escapa `& < > " '` para HTML o `\ { } & % $ # _ ~ ^` para LaTeX |
| `tmpl extract vars / tmpl has unclosed tags` | Extrae los nombres de variables requeridos y valida que las etiquetas estén cerradas |

---

## 4. Recetas prácticas en estilo tabular

### Receta 1: Flujo principal con `template`

Observa cómo los signos `=` y los pasos de transformación quedan alineados como una tabla limpia:

```ridgun
import template

fn :: renderizar perfil html (usuario : String) (es_admin : String) => String
      renderizar perfil html usuario es_admin =
        plantilla = "<h1>Hola {{user}}</h1>{{#admin}}<span class='badge'>Admin</span>{{/admin}}"
        vars      = [("user", usuario), ("admin", es_admin)]
        tmpl render html plantilla vars
```

### Receta 2: Composición segura y sin efectos laterales

Toda función de la lib `template` es componible con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import template

fn :: generar linea latex (metrica : String) => String
      generar linea latex metrica =
        -- Escapa automaticamente % _ & # para que LaTeX no falle
        tmpl render latex "Resultado: {{val}}" [("val", metrica)]
```

---

## 5. Bajo el capó: rendimiento, memoria RMM y garantías

- **Garantía algorítmica y de seguridad**: Prevención de XSS por defecto en `tmpl render html` (escapando `&`, `<`, `>`, `"`, `'`) mientras `{{{var}}}` permite inyectar fragmentos de confianza de forma explícita.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test_template.rg`.
