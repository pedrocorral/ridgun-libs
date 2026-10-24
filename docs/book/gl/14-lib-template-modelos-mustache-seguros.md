# Capítulo 14: A lib `template` — Modelos Mustache Seguros con Auto-Escape HTML e LaTeX

## 1. Por que existe a lib `template`?

Sexamos sinceros: montar páxinas HTML ou informes LaTeX concatenando cadeas á man é a receita perfecta para unha vulnerabilidade XSS (`<script>`) ou para que un simple símbolo `%` ou `_` rompa a compilación do teu PDF.

A lib **`template`** ofrece un motor **Mustache** sen lóxica arbitraria con auto-escape contextual (`TmplPlain`, `TmplHtml`, `TmplLatex`), substitución crúa explícita (`{{{raw}}}` / `{{&raw}}`), comentarios (`{{! ... }}`), seccións condicionais (`{{#sec}}...{{/sec}}`) e invertidas (`{{^sec}}...{{/sec}}`).

---

## 2. Artefactos, importación e arquitectura sen `libc`

En `ridgun-libs`, **`template`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/template.rg` (dominio `TMPL`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/template.rglib` | Distribución e importación directa con `import template` |
| **Ficheiro compilado** | `target/template.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libtemplate.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import template` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

---

## 3. Referencia rápida da API de `template`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `tmpl render / tmpl render html / tmpl render latex` | Renderiza modelos Mustache con auto-escape plano, HTML ou LaTeX |
| `tmpl escape html / tmpl escape latex` | Escapa `& < > " '` para HTML ou `\ { } & % $ # _ ~ ^` para LaTeX |
| `tmpl extract vars / tmpl has unclosed tags` | Extrae os nomes de variables requiridos e valida que as etiquetas estean pechadas |

---

## 4. Receitas prácticas en estilo tabular

### Receita 1: Fluxo principal con `template`

Observa como os signos `=` e os pasos de transformación quedan aliñados coma unha táboa limpa:

```ridgun
import template

fn :: renderizar perfil html (usuario : String) (es_admin : String) => String
      renderizar perfil html usuario es_admin =
        plantilla = "<h1>Hola {{user}}</h1>{{#admin}}<span class='badge'>Admin</span>{{/admin}}"
        vars      = [("user", usuario), ("admin", es_admin)]
        tmpl render html plantilla vars
```

### Receita 2: Composición segura e sen efectos laterais

Toda función da lib `template` é compoñible co resto das 32 libs de `ridgun-libs`:

```ridgun
import template

fn :: generar linea latex (metrica : String) => String
      generar linea latex metrica =
        -- Escapa automaticamente % _ & # para que LaTeX no falle
        tmpl render latex "Resultado: {{val}}" [("val", metrica)]
```

---

## 5. Baixo o capó: rendemento, memoria RMM e garantías

- **Garantía algorítmica e de seguridade**: Prevención de XSS por defecto en `tmpl render html` (escapando `&`, `<`, `>`, `"`, `'`) mentres `{{{var}}}` permite inxectar fragmentos de confianza de forma explícita.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test_template.rg`.
