# Kapitel 14: Lib:en `template` — Säkra Mustache-mallar med Automatisk HTML- och LaTeX-kodning

## 1. Varför finns lib:en `template`?

Låt oss vara ärliga: att bygga HTML-sidor eller LaTeX-rapporter genom manuell strängkonkatenering är ett säkert recept på XSS-sårbarheter (`<script>`) eller trasiga PDF-byggen så fort någon skriver `%` eller `_`.

Lib:en **`template`** erbjuder en logikfri **Mustache**-motor med kontextuell automatisk kodning (`TmplPlain`, `TmplHtml`, `TmplLatex`), explicit råinterpolering (`{{{raw}}}` / `{{&raw}}`), kommentarer (`{{! ... }}`) samt villkorliga (`{{#sec}}`) och inverterade sektioner (`{{^sec}}`).

---

## 2. Paket, import och arkitektur helt utan `libc`

I `ridgun-libs` är **`template`** en förstklassig **lib** placerad i `src/main/ridgun/lib/template.rg` (domän `TMPL`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/template.rglib` | Portabel distribution och direkt import med `import template` |
| **Kompilerat arkiv** | `target/template.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libtemplate.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import template` överst och anropar funktionerna med mellanslag eller understreck.

---

## 3. Snabbreferens för `template`-API:et

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `tmpl render / tmpl render html / tmpl render latex` | Renderar Mustache-mallar med enkel, HTML- eller LaTeX-autokodning |
| `tmpl escape html / tmpl escape latex` | Kodar `& < > " '` för HTML eller `\ { } & % $ # _ ~ ^` för LaTeX |
| `tmpl extract vars / tmpl has unclosed tags` | Extraherar obligatoriska variabelnamn och validerar taggbalans före rendering |

---

## 4. Praktiska recept i tabellform

### Recept 1: Huvudflöde med `template`

Lägg märke till hur `=`-tecknen och transformationsstegen linjeras som en ren tabell:

```ridgun
import template

fn :: renderizar perfil html (usuario : String) (es_admin : String) => String
      renderizar perfil html usuario es_admin =
        plantilla = "<h1>Hola {{user}}</h1>{{#admin}}<span class='badge'>Admin</span>{{/admin}}"
        vars      = [("user", usuario), ("admin", es_admin)]
        tmpl render html plantilla vars
```

### Recept 2: Säker komposition utan sidoeffekter

Varje funktion i lib:en `template` kan kombineras fritt med övriga 32 libs i `ridgun-libs`:

```ridgun
import template

fn :: generar linea latex (metrica : String) => String
      generar linea latex metrica =
        -- Escapa automaticamente % _ & # para que LaTeX no falle
        tmpl render latex "Resultado: {{val}}" [("val", metrica)]
```

---

## 5. Under huven: prestanda, RMM-minne och garantier

- **Algoritmisk garanti och säkerhet**: Inbyggt XSS-skydd som standard i `tmpl render html` (kodar `&`, `<`, `>`, `"`, `'`), medan `{{{var}}}` tillåter explicit råinjektion av betrodd markup.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test_template.rg`.
