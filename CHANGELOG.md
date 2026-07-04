# Changelog

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/),
y este proyecto sigue [Versionado Semántico](https://semver.org/lang/es/).

## [1.0.0] - 2026-07-04

Primera versión funcional y estable. `CurpMx::Validator` valida la formación de
un CURP conforme al Instructivo Normativo (DOF 18-10-2021) y a las Reglas para
la ejecución de los procedimientos para la asignación de la CURP.

### Agregado
- Validación del dígito verificador (posición 18) con el algoritmo del RENAPO,
  disponible también como `CurpMx::Validator.check_digit`.
- Aceptación del marcador de sexo `X` (CURPs de género no binario).
- Aceptación de CURPs anteriores y posteriores al año 2000 (homoclave `0-9` o
  `A-J` en la posición 17).
- Código de entidad `NE` (nacido en el extranjero).
- Normalización de la entrada a mayúsculas.
- Manejo seguro de entradas `nil` o que no son cadenas (regresan `format` en
  lugar de lanzar una excepción).

### Cambiado
- Catálogo de palabras altisonantes ampliado a las 82 entradas del Anexo 01.
- Catálogo de entidades corregido a los 33 códigos del Anexo 03 (se eliminó el
  código inexistente `CX`; la Ciudad de México es `DF`).
- Reescritura interna del validador: búsquedas con `Set`, extracción por
  posición fija y `String#match?`, sin asignar `MatchData`. La validación
  completa es ~2x más rápida que la implementación previa.

### Eliminado
- Dependencia de `parslet`. La gema ya no tiene dependencias en tiempo de
  ejecución (solo la librería estándar de Ruby).

### Corregido
- Los errores de `state` y `problematic_name` lanzaban `NoMethodError` porque
  el arreglo de errores nunca se inicializaba.
- El formato rechazaba todo CURP emitido a partir del año 2000 (posición 17 con
  letra).

[1.0.0]: https://github.com/hslzr/curp_mx/releases/tag/v1.0.0
