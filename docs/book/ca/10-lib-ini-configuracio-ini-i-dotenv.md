# Capítol 10: La lib `ini` — Fitxers `.ini` per Seccions, `.env` i Interpolació de Variables

## 1. Per què existeix la lib `ini`?

Siguem sincers: els fitxers `.env` i `.ini` semblen trivials fins que algú hi afegeix `export KEY="valor # amb coixinet"`, comentaris `;` al final de la línia o referències creuades entre variables.

La lib **`ini`** analitza configuracions `.ini` amb seccions (`[database]`) i fitxers `.env` amb prefixos `export`, preservant símbols `#` i `;` dins de cometes i resolent interpolacions de variables a `dotenv parse`.

---

## 2. Artefactes, importació i arquitectura sense `libc`

A `ridgun-libs`, **`ini`** és una **lib** de primera classe situada a `src/main/ridgun/lib/ini.rg` (domini `INI`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/ini.rglib` | Distribució i importació directa amb `import ini` |
| **Fitxer compilat** | `target/ini.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libini.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Per fer servir aquesta lib en qualsevol fitxer `.rg`, n'hi ha prou de declarar `import ini` a la capçalera i cridar les seves funcions amb espais o guions baixos indistintament.

---

## 3. Referència ràpida de l'API de `ini`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `ini parse / ini stringify` | Analitza text `.ini` per seccions en `IniDoc` i el serialitza de tornada |
| `ini get / ini get int / ini get bool / ini set` | Consultes tipades per secció+clau (`""` per a secció global) i actualització immutable |
| `ini sections / ini section map` | Llista els noms de secció o extreu el mapa `[String String]` d'una secció |
| `dotenv parse` | Analitza fitxers `.env` (`export K=V`, cometes, comentaris i expansió de variables) |

---

## 4. Receptes pràctiques en estil tabular

### Recepta 1: Flux principal amb `ini`

Observa com els signes `=` i els passos de transformació queden alineats com una taula neta:

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

### Recepta 2: Composició segura i sense efectes laterals

Tota funció de la lib `ini` és componible amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import ini

fn :: actualizar puerto (doc : IniDoc) (nuevo : String) => String
      actualizar puerto doc nuevo =
        doc2 = ini set doc "database" "port" nuevo
        ini stringify doc2
```

---

## 5. Sota el capó: rendiment, memòria RMM i garanties

- **Garantia algorísmica i de seguretat**: Respecte total pels caràcters `#` i `;` quan apareixen entre cometes simples o dobles, i conversió booleana flexible (`true/1/yes/on` vs `false/0/no/off`).
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test_ini.rg`.
