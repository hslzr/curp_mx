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

## Notas

- Se aceptan los marcadores de sexo `H`, `M` y `X`.
- Se aceptan CURPs anteriores y posteriores al año 2000 (la homoclave puede ser
  dígito o letra).
- El dígito verificador (posición 18) aún **no** se valida; ver la sección de
  pendientes.

## Pendientes

- Validar el dígito verificador contra el algoritmo del RENAPO.

## Desarrollo

```bash
bin/setup        # instala dependencias
bundle exec rspec # corre las pruebas
```

## Licencia

Disponible como software libre bajo los términos de la [licencia MIT](LICENSE.txt).
