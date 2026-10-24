# 14. kapitulua: `template` lib-a — HTML eta LaTeX Auto-ihesa duten Mustache Txantiloi Seguruak

## 1. Zergatik existitzen da `template` lib-a?

Izan gaitezen zintzoak: HTML orriak edo LaTeX txostenak kateak eskuz lotuz muntatzea XSS ahultasun baterako (`<script>`) edo `%` zein `_` ikur soil batek zure PDFaren konpilazioa apurtzeko errezeta perfektua da.

**`template`** lib-ak logika arbitrariorik gabeko **Mustache** motor bat eskaintzen du testuinguruko auto-ihesarekin (`TmplPlain`, `TmplHtml`, `TmplLatex`), ordezkapen gordin esplizituarekin (`{{{raw}}}` / `{{&raw}}`), iruzkinekin (`{{! ... }}`) eta atal baldintzatuekin (`{{#sec}}` / `{{^sec}}`).

---

## 2. Artefaktuak, inportazioa eta `libc` gabeko arkitektura

`ridgun-libs`-en, **`template`** lehen mailako **lib** bat da, `src/main/ridgun/lib/template.rg` bidean kokatua (`TMPL` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/template.rglib` | Banaketa eta inportazio zuzena `import template` bidez |
| **Fitxategi konpilatua** | `target/template.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libtemplate.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import template` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

---

## 3. `template` APIaren erreferentzia azkarra

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `tmpl render / tmpl render html / tmpl render latex` | Mustache txantiloiak errenderizatzen ditu auto-ihes lau, HTML edo LaTeXekin |
| `tmpl escape html / tmpl escape latex` | `& < > " '` HTMLrako edo `\ { } & % $ # _ ~ ^` LaTeXerako ihes egiten ditu |
| `tmpl extract vars / tmpl has unclosed tags` | Beharrezko aldagai-izenak erauzten ditu eta etiketen oreka egiaztatzen du |

---

## 4. Errezeta praktikoak estilo taularatuan

### 1. errezeta: Fluxu nagusia `template` erabiliz

Ikusi nola `=` ikurrak eta eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren:

```ridgun
import template

fn :: renderizar perfil html (usuario : String) (es_admin : String) => String
      renderizar perfil html usuario es_admin =
        plantilla = "<h1>Hola {{user}}</h1>{{#admin}}<span class='badge'>Admin</span>{{/admin}}"
        vars      = [("user", usuario), ("admin", es_admin)]
        tmpl render html plantilla vars
```

### 2. errezeta: Konposizio segurua eta albo-ondoriorik gabea

`template` lib-eko funtzio oro `ridgun-libs`-eko gainerako 32 lib-ekin konposa daiteke:

```ridgun
import template

fn :: generar linea latex (metrica : String) => String
      generar linea latex metrica =
        -- Escapa automaticamente % _ & # para que LaTeX no falle
        tmpl render latex "Resultado: {{val}}" [("val", metrica)]
```

---

## 5. Kaputaren azpian: errendimendua, RMM memoria eta bermeak

- **Berme algoritmikoa eta segurtasunekoa**: XSS prebentzioa lehenetsita `tmpl render html`-n (`&`, `<`, `>`, `"`, `'` ihes eginez), `{{{var}}}`-k konfiantzazko zatiak esplizituki txertatzea ahalbidetzen duen bitartean.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test_template.rg` suite automatizatuaren bidez.
