# CurpMx

Librería para validar CURPs. Nada complicado, es esencialmente un regex que
regresa una lista de errores de haber algunos.

```ruby
    curp = CurpMx::Validator.new("JOJO200927HNLJJO09")
    curp.valid?
    #=> true | false
    
    curp.errors
    #=> {
        :curp => ["Invalid format"],
        :birth_day => ["Invalid day"]
    }
    
```

## ¿Español?

El README estaba en inglés hasta que caí en la cuenta que la librería va
dirigida a un público mexicano... No hay necesidad de explicarlo en otro idioma.
Opino.

## Instrucciones

#### Validación rápida

```ruby
CurpMx::Validator.valid?("curp")
#=> true | false
```

### Validación a detalle

```ruby
validator = CurpMx::Validator.new("curp")
# El método #validate es llamado al inicializarlo

validator.valid?
#=> false

validator.errors
#=> [
      format: ["Invalid format"],
      ...
    ]


```

## Validaciones

| Valor | Error |
|:--- | :---|
| `format` | El formato no coincide con el de un CURP |
| `state` | El ESTADO no coincide con las abreviaciones del RENAPO |
| `problematic_name` | Las iniciales forman una palabra prohibida. (Ej. 'CACA') |
| `birth_day` | Día de nacimiento `<= 0` o `> 31` |
| `birth_month` | Mes de nacimiento `<= 0` o `> 12` |
| `birth_date` | Fecha de nacimiento inexistente (Ej. `31/02/1989`) |
