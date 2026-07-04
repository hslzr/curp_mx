# frozen_string_literal: true

require 'date'

module CurpMx
  # Validates a CURP's format and a few data points in it.
  # Restored from commit bfbe0b0^ with the state/name crash and the
  # post-2000 homoclave format bugs fixed.
  class Validator
    attr_reader :errors, :raw_input

    # Basic CURP regex structure.
    #   positions 1-4   : name initials (surnames + given name)
    #   positions 5-10  : birth date (YYMMDD)
    #   position  11    : sex (H / M / X)
    #   positions 12-13 : state (RENAPO)
    #   positions 14-16 : internal consonants
    #   position  17    : homoclave (digit for <2000, letter for >=2000)
    #   position  18    : check digit
    REGEX = /\A(?<father_initial>[A-Z]{2})
                (?<mother_initial>[A-Z]{1})
                (?<name_initial>[A-Z]{1})
                (?<birth_year>[0-9]{2})
                (?<birth_month>[0-1][0-9])
                (?<birth_day>[0-3][0-9])
                (?<sex>[HMX])
                (?<state>[A-Z]{2})
                (?<father_consonant>[^AEIOU])
                (?<mother_consonant>[^AEIOU])
                (?<name_consonant>[^AEIOU])
                (?<homoclave>[A-Z0-9])
                (?<check_digit>[0-9])\z/x.freeze

    # States' initials as listed in
    # Registro Nacional de Población (RENAPO).
    # Includes both DF and CX for Mexico City.
    STATES_RENAPO = %w[AS BC BS CC CS CH CL CM DF CX DG GT GR HG JC MC MN MS
                       NT NL OC PL QT QR SP SL SR TC TS TL VZ YN ZS].freeze

    # Problematic name initials (RENAPO substitutes the 2nd letter with X
    # when the first four letters spell one of these).
    NAME_ISSUES = %w[BACA LOCO BUEI BUEY MAME CACA MAMO
                     CAGA MEAS CAGO MEON CAKA MIAR CAKO MION COGE
                     MOCO COGI MOKO COJA MULA COJE MULO COJI NACA
                     COJO NACO COLA PEDA CULO PEDO FALO PENE FETO
                     PIPI GETA PITO GUEI POPO GUEY PUTA JETA PUTO
                     JOTO QULO KACA RATA KACO ROBA KAGA ROBE KAGO
                     ROBO KAKA RUIN KAKO SENO KOGE TETA KOGI VACA
                     KOJA VAGA KOJE VAGO KOJI VAKA KOJO VUEI KOLA
                     VUEY KULO WUEI LILO WUEY LOCA CACO MEAR].freeze

    def self.valid?(curp)
      new(curp).valid?
    end

    def initialize(curp)
      @raw_input = curp
      @errors = {}

      validate
    end

    def valid?
      @errors.empty?
    end

    def validate
      @md = REGEX.match(@raw_input)

      if @md.nil?
        add_error(:format, 'Invalid format')
        return false
      end

      validate_state
      validate_name_initials
      validate_birth_date
      validate_date_exists
    end

    private

    # Appends a message under +key+, creating the array on first use.
    # (The original crashed here because :state and :problematic_name
    # were never initialized before <<.)
    def add_error(key, message)
      (@errors[key] ||= []) << message
    end

    def validate_state
      return if STATES_RENAPO.include? @md[:state]

      add_error(:state, "Invalid state: '#{@md[:state]}'")
    end

    def validate_name_initials
      return unless NAME_ISSUES.include?(name_initials)

      add_error(:problematic_name, "Problematic name initials: '#{name_initials}'")
    end

    def validate_birth_date
      validate_birth_day
      validate_birth_month
    end

    def validate_birth_day
      birth_day = @md[:birth_day].to_i
      return unless birth_day <= 0 || birth_day > 31

      add_error(:birth_day, "Invalid birth day: '#{@md[:birth_day]}'")
    end

    def validate_birth_month
      birth_month = @md[:birth_month].to_i
      return unless birth_month <= 0 || birth_month > 12

      add_error(:birth_month, "Invalid birth month: '#{@md[:birth_month]}'")
    end

    def validate_date_exists
      return if Date.valid_date?(birth_year, @md[:birth_month].to_i, @md[:birth_day].to_i)

      add_error(:birth_date,
                "Invalid birth date (YYYY-mm-dd): #{birth_year}-#{@md[:birth_month]}-#{@md[:birth_day]}")
    end

    # Full 4-digit year, using the homoclave to pick the century:
    # a digit at position 17 means <2000, a letter means >=2000.
    # This keeps leap-year checks (e.g. Feb 29) correct.
    def birth_year
      century = @md[:homoclave].match?(/[A-Z]/) ? 2000 : 1900
      century + @md[:birth_year].to_i
    end

    def name_initials
      [@md[:father_initial], @md[:mother_initial], @md[:name_initial]].join
    end
  end
end
