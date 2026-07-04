# CurpMx

Librería para validar CURPs. Nada complicado: esencialmente un regex más un
par de comprobaciones que regresan una lista de errores, de haber alguno.

Sin dependencias en tiempo de ejecución (solo usa la librería estándar de Ruby).

## Instalación

Agrega la gema a tu `Gemfile`:

```ruby
gem "curp_mx"
```

Y luego:

```bash
bundle install
```

O instálala directamente:

```bash
gem install curp_mx
```

## Uso

### Validación rápida

Cuando solo te interesa saber si el CURP es válido o no:

```ruby
CurpMx::Validator.valid?("TOGG641009HJCRML99")
#=> true | false
```

### Validación a detalle

Cuando necesitas saber *por qué* un CURP es inválido:

```ruby
validator = CurpMx::Validator.new("TOGG641009HZZRML99")
# El método #validate se llama automáticamente al inicializar.

validator.valid?
#=> false

validator.errors
#=> { :state => ["Invalid state: 'ZZ'"] }
```

Si el formato no coincide con el de un CURP, la validación se detiene ahí y
solo se reporta el error de `format`:

```ruby
CurpMx::Validator.new("no-es-un-curp").errors
#=> { :format => ["Invalid format"] }
```

Un CURP válido regresa un hash de errores vacío:

```ruby
validator = CurpMx::Validator.new("TOGG641009HJCRML99")
validator.valid?  #=> true
validator.errors  #=> {}
```

## Validaciones

`errors` es un `Hash` donde cada llave es el campo con problema y su valor es un
arreglo de mensajes.

| Llave | Significado |
|:--- |:---|
| `format` | El formato no coincide con el de un CURP |
| `state` | El estado no coincide con las abreviaciones del RENAPO |
| `problematic_name` | Las iniciales forman una palabra altisonante (ej. `CACA`) |
| `birth_day` | Día de nacimiento `<= 0` o `> 31` |
| `birth_month` | Mes de nacimiento `<= 0` o `> 12` |
| `birth_date` | Fecha de nacimiento inexistente (ej. `30/02/1989`) |
| `check_digit` | El dígito verificador (posición 18) no coincide con el calculado |

## Notas

- Se aceptan los marcadores de sexo `H`, `M` y `X`.
- Se aceptan CURPs anteriores y posteriores al año 2000 (la homoclave puede ser
  dígito o letra).
- Se valida el dígito verificador (posición 18) con el algoritmo del RENAPO.
  También se puede calcular por separado a partir de los primeros 17 caracteres:

  ```ruby
  CurpMx::Validator.check_digit("BEBE900101HDFXXX0") #=> 7
  ```

## Dígito verificador

### Cómo se dedujo

El algoritmo del dígito verificador **no aparece publicado** en el Instructivo
Normativo: éste solo describe la posición 18 como *"un carácter asignado […] a
través de la aplicación de un algoritmo que permite calcular y verificar la
correcta conformación de la clave"*, sin dar la fórmula ni la tabla de valores.

Por eso el algoritmo de esta gema es, en parte, **ingeniería inversa**. Se
partió del algoritmo estándar del RENAPO que circula públicamente y se confirmó
de forma empírica contra CURPs reales, válidas y conocidas: para cada una se
calculó el dígito a partir de sus primeros 17 caracteres y se comparó con el
carácter 18 real. Varias CURPs independientes coinciden, así que la confianza es
alta, pero conviene tenerlo presente: **es la única regla de la gema que no está
respaldada por una fuente oficial directa**, sino por verificación empírica.

Sugiero ampliamente hacer validaciones con CURPs propias para corroborar que, en
CURPs ya existentes y en circulación, este algoritmo siga siendo válido. Si tu
CURP es detectada como no válida puedes crear un issue en este repo para refinar
el cálculo.

### Cómo funciona

Dados los primeros 17 caracteres del CURP:

1. **Valor de cada carácter.** Los dígitos `0`–`9` valen `0`–`9`. Las letras
   `A`–`N` valen `10`–`23`, y las letras `O`–`Z` valen `25`–`36`.

2. **Suma ponderada.** Cada valor se multiplica por un peso descendente según su
   posición: el primer carácter por `18`, el segundo por `17`, … y el carácter
   17 por `2`. Se suman todos los productos.

3. **Complemento a 10.** El dígito verificador es `(10 - (suma mod 10)) mod 10`,
   siempre un número del `0` al `9`.

Ejemplo con `BEBE900101HDFXXX0` (17 caracteres):

```
  B  E  B  E  9  0  0  1  0  1  H  D  F  X  X  X  0
 11 14 11 14  9  0  0  1  0  1 17 13 15 34 34 34  0   ← valor
×18 17 16 15 14 13 12 11 10  9  8  7  6  5  4  3  2   ← peso

suma = 1693 ;  1693 mod 10 = 3 ;  (10 - 3) mod 10 = 7  →  dígito = 7
```

Por eso `BEBE900101HDFXXX07` es válido.

Internamente el cálculo se hace sobre los bytes ASCII (los tres tramos de
valores son contiguos), sin construir tablas ni objetos, para que sea rápido.

## Desarrollo

```bash
bin/setup        # instala dependencias
bundle exec rspec # corre las pruebas
```

## Normativa
La gema en su estado actual valida la formación del CURP de acuerdo al
**Instructivo Normativo Para La Asignación De La Clave Única De Registro De
Población**, publicado en el Diario Oficial de la Federación el día 18 de
Octubre de 2021. El documento en formato PDF puede ser leído [en este
enlace](https://www.gob.mx/cms/uploads/attachment/file/337251/Instructivo_Normativo_para_la_Asignacion_de_la_CURP.pdf)

Sin embargo, cabe aclarar que **no soy abogado**, así que mis fuentes podrían no
ser las más precisas. Durante mi investigación, encontré además las [REGLAS PARA
LA EJECUCIÓN DE LOS PROCEDIMIENTOS PARA LA ASIGNACIÓN DE LA CLAVE ÚNICA DE
POBLACIÓN](https://www.gob.mx/cms/uploads/attachment/file/960109/Reglas_para_la_Ejecucion_de_los_Procedimientos_para_la_Asignacion_de_la_CURP.pdf),
que si bien no contradice el documento anterior, ésta tiene ejemplos más
precisos y un par de anexos para la validación de los datos – la lista de
palabras altisonantes en la página 86, por ejemplo.

La gema actual permite el uso de la letra `X` en el
género del individuo a pesar de no estar dentro de la normativa; esto debido a
un antecedente de [una CURP emitida en
2023](https://quinto-poder.mx/orgullomx/2023/2/23/expiden-la-primera-curp-de-genero-no-binario-18792.html),
lo que implica que más CURPs con formato similar podrían existir allá afuera.

## Licencia

Disponible como software libre bajo los términos de la [licencia MIT](LICENSE.txt).
