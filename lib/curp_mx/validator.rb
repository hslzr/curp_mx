module CurpMx
  class Validator
    attr_reader :errors, :raw_input

    # Basic CURP regex structure
    REGEX = /\A(?<father_initial>[A-Z]{2})
                (?<mother_initial>[A-Z]{1})
                (?<name_initial>[A-Z]{1})
                (?<birth_year>[0-9]{2})
                (?<birth_month>[0-1][0-9])
                (?<birth_day>[0-3][0-9])
                (?<genre>[HM])
                (?<state>[A-Z]{2})
                (?<father_consonant>[^AEIOU])
                (?<mother_consonant>[^AEIOU])
                (?<name_consonant>[^AEIOU])
                (?<homokey>[0-9]{2})\z/x.freeze

    # States' initials as listed in
    # Registro Nacional de Población (RENAPO)
    STATES_RENAPO = %w(AS BC BS CC CS CH CL CM DF CX DG GT GR HG JC MC MN MS
                    NT NL OC PL QT QR SP SL SR TC TS TL VZ YN ZS).freeze

    # Problematic name initials 
    ISSUES = %w(BACA LOCO BUEI BUEY MAME CACA MAMO
      CAGA MEAS CAGO MEON CAKA MIAR CAKO MION COGE
      MOCO COGI MOKO COJA MULA COJE MULO COJI NACA
      COJO NACO COLA PEDA CULO PEDO FALO PENE FETO
      PIPI GETA PITO GUEI POPO GUEY PUTA JETA PUTO
      JOTO QULO KACA RATA KACO ROBA KAGA ROBE KAGO
      ROBO KAKA RUIN KAKO SENO KOGE TETA KOGI VACA
      KOJA VAGA KOJE VAGO KOJI VAKA KOJO VUEI KOLA 
      VUEY KULO WUEI LILO WUEY LOCA CACO MEAR).freeze

    def initialize(str)
      @raw_input = str
      @errors = {}
    end

    def valid?
      match_data = REGEX.match(@raw_input)

      unless !!match_data
        @errors[:curp] << 'Invalid format'
        return false
      end


      unless STATES_RENAPO.include? match_data[:state]
        @errors[:curp] << "Invalid state: '#{match_data[:state]}'"
      end

      if ISSUES.include?(name_initials)
        @errors[:curp] << "Invalid name initials: '#{name_initials}'"
      end

      birth_day   = match_data[:birth_day].to_i
      birth_month = match_data[:birth_month].to_i
      birth_year  = match_data[:birth_year].to_i

      if birth_day <= 0 || birth_day > 31
        @errors[:birth_day] << "Invalid birth day: '#{match_data[:birth_day]}'"
      end

      if birth_month <= 0 || birth_month > 12
        @errors[:birth_month] << "Invalid birth month: '#{match_data[:birth_month]}'"
      end

      return @errors.empty?
    end

    private

    def name_initials
      @raw_input[0..3]&.upcase || :BACA
    end
  end
end
