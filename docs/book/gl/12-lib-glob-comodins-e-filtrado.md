# Capítulo 12: A lib `glob` — Padróns de Comodíns (`*`, `?`, `[a-z]`) e Filtrado de Listas

## 1. Por que existe a lib `glob`?

Sexamos sinceros: usar unha expresión regular completa só para comprobar se un ficheiro remata en `*.rg` ou comeza por `test_[0-9]*.rg` é matar moscas a cañonazos.

A lib **`glob`** implementa coincidencia exacta de comodíns de shell (`*`, `?`, clases `[a-z]`, clases negadas `[!0-9]` / `[^a-z]`), variantes insensibles a maiúsculas (`glob match ci`) e filtrado directo de listas de rutas ou nomes.

---

## 2. Artefactos, importación e arquitectura sen `libc`

En `ridgun-libs`, **`glob`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/glob.rg` (dominio `GLOB`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/glob.rglib` | Distribución e importación directa con `import glob` |
| **Ficheiro compilado** | `target/glob.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libglob.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import glob` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

---

## 3. Referencia rápida da API de `glob`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `glob match / glob match ci` | Coincidencia de padróns glob sensible e insensible a maiúsculas ASCII |
| `glob filter / glob any match` | Filtra `[String]` segundo un padrón ou comproba se coincide algún padrón dunha lista |
| `glob has magic` | Detecta se unha cadea contén metacaracteres de comodín (`*`, `?`, `[`) |

---

## 4. Receitas prácticas en estilo tabular

### Receita 1: Fluxo principal con `glob`

Observa como os signos `=` e os pasos de transformación quedan aliñados coma unha táboa limpa:

```ridgun
import glob

fn :: seleccionar fuentes ridgun (archivos : [String]) => [String]
      seleccionar fuentes ridgun archivos =
        glob filter "test_[a-z]*.rg" archivos
```

### Receita 2: Composición segura e sen efectos laterais

Toda función da lib `glob` é compoñible co resto das 32 libs de `ridgun-libs`:

```ridgun
import glob

fn :: es ruta excluida (ruta : String) => Bool
      es ruta excluida ruta =
        glob any match ["*.tmp", "*.bak", "target/*"] ruta
```

---

## 5. Baixo o capó: rendemento, memoria RMM e garantías

- **Garantía algorítmica e de seguridade**: Colapso automático de estrelas consecutivas (`***` $\rightarrow$ `*`) para evitar retrocesos redundantes e manexo seguro de corchetes sen pechar `[`.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test_glob.rg`.
