# Capítulo 21: La lib `test` — Primitivas de Aserción Unitaria y Funcional (`RG-011`)

## 1. ¿Por qué existe la lib `test`?

Seamos sinceros: cuando un framework de tests requiere macros mágicas, reflexión en tiempo de ejecución o un runner externo pesado, escribir pruebas deja de ser inmediato.

La lib **`test`** (`RG-011`) proporciona aserciones puras, polimórficas y específicas de tipo que emiten diagnósticos claros `[FAIL]` con los valores esperado y obtenido y terminan con código de salida `1` en cuanto falla una invariante.

---

## 2. Artefactos, importación y arquitectura sin `libc`

En `ridgun-libs`, **`test`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/test.rg` (dominio `TST`). Al compilar con `stable bundle`, se empaqueta en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/test.rglib` | Distribución e importación directa con `import test` |
| **Archivo compilado** | `target/test.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libtest.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import test` en el encabezado y llamar a sus funciones con espacios o guiones bajos indistintamente.

---

## 3. Referencia rápida de la API de `test`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `assert equals / assert eq : A -> A -> String -> ()` | Aserción polimórfica de igualdad con etiqueta descriptiva del caso de prueba |
| `assert int equals / assert str eq` | Aserciones especializadas de igualdad para `Int` y `String` |
| `assert true / assert false / assert not` | Aserciones de invariantes booleanas (`True` / `False`) |
| `assert ok : Int -> String -> ()` | Verifica que un código de estado del sistema o socket sea `0` (`OK`) |

---

## 4. Recetas prácticas en estilo tabular

### Receta 1: Flujo principal con `test`

Observa cómo los signos `=` y los pasos de transformación quedan alineados como una tabla limpia:

```ridgun
import test
import math

fn :: suite matematicas () => ()
      suite matematicas =
        _ = assert int equals 12 (math gcd 36 60) "MCD de 36 y 60"
        _ = assert true (math is prime 97) "97 es primo"
        echo "[PASS] suite matematicas"
```

### Receta 2: Composición segura y sin efectos laterales

Toda función de la lib `test` es componible con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import test

fn :: verificar codigo sistema (rc : Int) => ()
      verificar codigo sistema rc =
        assert ok rc "operacion de descriptor exitosa"
```

---

## 5. Bajo el capó: rendimiento, memoria RMM y garantías

- **Garantía algorítmica y de seguridad**: Las 30 suites de pruebas de `ridgun-libs` (`src/test/ridgun/test_*.rg`, más de 4 000 líneas) se ejecutan con esta misma lib mediante `stable test`.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test_test.rg`.
