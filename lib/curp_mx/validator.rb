# frozen_string_literal: true

require 'date'
require 'set'

module CurpMx
  # Validates a CURP's format and a few data points in it.
  #
  # Hot-path notes: the format check uses String#match? (no MatchData
  # allocation) and fields are read by fixed offset. Lookups go through
  # frozen Sets, not Array scans. See spec + benchmarks.
  class Validator
    attr_reader :errors, :raw_input

    # Format only — no captures. Fields are sliced by offset afterwards.
    #   0-3  name initials      4-5 year   6-7 month   8-9 day
    #   10   sex                11-12 state            13-15 consonants
    #   16   homoclave          17 check digit
    FORMAT = /\A[A-Z]{4}\d{2}[0-1]\d[0-3]\d[HMX][A-Z]{2}[^AEIOU]{3}[A-Z0-9]\d\z/.freeze

    # States' initials as listed in the Registro Nacional de Población
    # (RENAPO). Includes both DF and CX for Mexico City.
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

    # O(1) lookup copies of the constants above (the public constants stay
    # as readable frozen Arrays).
    STATES = STATES_RENAPO.to_set.freeze
    WORDS  = NAME_ISSUES.to_set.freeze

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
      unless @raw_input.is_a?(String) && FORMAT.match?(@raw_input)
        add_error(:format, 'Invalid format')
        return false
      end

      validate_state
      validate_name_initials
      validate_birth_date
      validate_date_exists
    end

    private

    def add_error(key, message)
      (@errors[key] ||= []) << message
    end

    def validate_state
      state = @raw_input[11, 2]
      return if STATES.include?(state)

      add_error(:state, "Invalid state: '#{state}'")
    end

    def validate_name_initials
      initials = @raw_input[0, 4]
      return unless WORDS.include?(initials)

      add_error(:problematic_name, "Problematic name initials: '#{initials}'")
    end

    def validate_birth_date
      day = @raw_input[8, 2].to_i
      add_error(:birth_day, "Invalid birth day: '#{@raw_input[8, 2]}'") if day <= 0 || day > 31

      month = @raw_input[6, 2].to_i
      add_error(:birth_month, "Invalid birth month: '#{@raw_input[6, 2]}'") if month <= 0 || month > 12
    end

    def validate_date_exists
      return if Date.valid_date?(birth_year, @raw_input[6, 2].to_i, @raw_input[8, 2].to_i)

      add_error(:birth_date,
                "Invalid birth date (YYYY-mm-dd): #{birth_year}-#{@raw_input[6, 2]}-#{@raw_input[8, 2]}")
    end

    # Full 4-digit year, using the homoclave to pick the century: a digit
    # at position 17 means <2000, a letter means >=2000. Keeps leap-year
    # checks (e.g. Feb 29) correct. Letters sort after '9' in ASCII.
    def birth_year
      century = @raw_input[16] >= 'A' ? 2000 : 1900
      century + @raw_input[4, 2].to_i
    end
  end
end
