# Capítulo 21: A lib `test` — Primitivas de Aserción Unitaria e Funcional (`RG-011`)

## 1. Por que existe a lib `test`?

Sexamos sinceros: cando un framework de tests require macros máxicas, reflexión en tempo de execución ou un runner externo pesado, escribir probas deixa de ser inmediato.

A lib **`test`** (`RG-011`) proporciona asercións puras, polimórficas e específicas de tipo que emiten diagnósticos claros `[FAIL]` cos valores esperado e obtido e rematan con código de saída `1` en canto falla unha invariante.

---

## 2. Artefactos, importación e arquitectura sen `libc`

En `ridgun-libs`, **`test`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/test.rg` (dominio `TST`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/test.rglib` | Distribución e importación directa con `import test` |
| **Ficheiro compilado** | `target/test.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libtest.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import test` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

---

## 3. Referencia rápida da API de `test`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `assert equals / assert eq : A -> A -> String -> ()` | Aserción polimórfica de igualdade con etiqueta descritiva do caso de proba |
| `assert int equals / assert str eq` | Asercións especializadas de igualdade para `Int` e `String` |
| `assert true / assert false / assert not` | Asercións de invariantes booleanas (`True` / `False`) |
| `assert ok : Int -> String -> ()` | Verifica que un código de estado do sistema ou socket sexa `0` (`OK`) |

---

## 4. Receitas prácticas en estilo tabular

### Receita 1: Fluxo principal con `test`

Observa como os signos `=` e os pasos de transformación quedan aliñados coma unha táboa limpa:

```ridgun
import test
import math

fn :: suite matematicas () => ()
      suite matematicas =
        _ = assert int equals 12 (math gcd 36 60) "MCD de 36 y 60"
        _ = assert true (math is prime 97) "97 es primo"
        echo "[PASS] suite matematicas"
```

### Receita 2: Composición segura e sen efectos laterais

Toda función da lib `test` é compoñible co resto das 32 libs de `ridgun-libs`:

```ridgun
import test

fn :: verificar codigo sistema (rc : Int) => ()
      verificar codigo sistema rc =
        assert ok rc "operacion de descriptor exitosa"
```

---

## 5. Baixo o capó: rendemento, memoria RMM e garantías

- **Garantía algorítmica e de seguridade**: As 30 suites de probas de `ridgun-libs` (`src/test/ridgun/test_*.rg`, máis de 4 000 liñas) execútanse con esta mesma lib mediante `stable test`.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test_test.rg`.
