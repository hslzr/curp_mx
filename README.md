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

Sin embargo, cabe aclara que **no soy abogado**, así que mis fuentes podrían no
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
