# CurpMx

~~Simple~~ ~~Minimal~~ Blazing fast library to check if a mexican CURP is valid.

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