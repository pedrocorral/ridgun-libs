# Capítol 14: La lib `template` — Plantilles Mustache Segures amb Auto-Escapament HTML i LaTeX

## 1. Per què existeix la lib `template`?

Siguem sincers: muntar pàgines HTML o informes LaTeX concatenant cadenes a mà és la recepta perfecta per a una vulnerabilitat XSS (`<script>`) o perquè un simple símbol `%` o `_` trenqui la compilació del teu PDF.

La lib **`template`** ofereix un motor **Mustache** sense lògica arbitrària amb auto-escapament contextual (`TmplPlain`, `TmplHtml`, `TmplLatex`), substitució crua explícita (`{{{raw}}}` / `{{&raw}}`), comentaris (`{{! ... }}`), seccions condicionals (`{{#sec}}...{{/sec}}`) i invertides (`{{^sec}}...{{/sec}}`).

---

## 2. Artefactes, importació i arquitectura sense `libc`

A `ridgun-libs`, **`template`** és una **lib** de primera classe situada a `src/main/ridgun/lib/template.rg` (domini `TMPL`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/template.rglib` | Distribució i importació directa amb `import template` |
| **Fitxer compilat** | `target/template.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libtemplate.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Per fer servir aquesta lib en qualsevol fitxer `.rg`, n'hi ha prou de declarar `import template` a la capçalera i cridar les seves funcions amb espais o guions baixos indistintament.

---

## 3. Referència ràpida de l'API de `template`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `tmpl render / tmpl render html / tmpl render latex` | Renderitza plantilles Mustache amb auto-escapament pla, HTML o LaTeX |
| `tmpl escape html / tmpl escape latex` | Escapa `& < > " '` per a HTML o `\ { } & % $ # _ ~ ^` per a LaTeX |
| `tmpl extract vars / tmpl has unclosed tags` | Extreu els noms de variables requerits i valida que les etiquetes estiguin tancades |

---

## 4. Receptes pràctiques en estil tabular

### Recepta 1: Flux principal amb `template`

Observa com els signes `=` i els passos de transformació queden alineats com una taula neta:

```ridgun
import template

fn :: renderizar perfil html (usuario : String) (es_admin : String) => String
      renderizar perfil html usuario es_admin =
        plantilla = "<h1>Hola {{user}}</h1>{{#admin}}<span class='badge'>Admin</span>{{/admin}}"
        vars      = [("user", usuario), ("admin", es_admin)]
        tmpl render html plantilla vars
```

### Recepta 2: Composició segura i sense efectes laterals

Tota funció de la lib `template` és componible amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import template

fn :: generar linea latex (metrica : String) => String
      generar linea latex metrica =
        -- Escapa automaticamente % _ & # para que LaTeX no falle
        tmpl render latex "Resultado: {{val}}" [("val", metrica)]
```

---

## 5. Sota el capó: rendiment, memòria RMM i garanties

- **Garantia algorísmica i de seguretat**: Prevenció d'XSS per defecte a `tmpl render html` (escapant `&`, `<`, `>`, `"`, `'`) mentre `{{{var}}}` permet injectar fragments de confiança de forma explícita.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test_template.rg`.
