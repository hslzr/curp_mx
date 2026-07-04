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
    #
    # Position 16 (homoclave/century): 0-9 for births before 2000, A-J for
    # 2000 onward, per the Instructivo Normativo (DOF 18-10-2021).
    # Sex accepts X (non-binary CURPs issued since 2023) beyond the H/M
    # in that same text.
    FORMAT = /\A[A-Z]{4}\d{2}[0-1]\d[0-3]\d[HMX][A-Z]{2}[^AEIOU]{3}[0-9A-J]\d\z/.freeze

    # Entity codes for positions 12-13, from Anexo 03 "Catálogo de
    # Entidades Federativas para la conformación de la CURP" of the
    # Instructivo Normativo (DOF 18-10-2021). 32 entities (Mexico City is
    # DF; there is no CX) plus NE for people born abroad.
    STATES_RENAPO = %w[AS BC BS CC CL CM CS CH DF DG GT GR HG JC MC MN MS
                       NT NL OC PL QT QR SP SL SR TC TS TL VZ YN ZS NE].freeze

    # Problematic name initials (RENAPO substitutes the 2nd letter with X
    # when the first four letters spell one of these). Full catalog of 82
    # words from Anexo 01 "Catálogo de palabras altisonantes" of the
    # Instructivo Normativo (DOF 18-10-2021).
    NAME_ISSUES = %w[BACA BAKA BUEI BUEY CACA CACO CAGA CAGO CAKA CAKO
                     COGE COGI COJA COJE COJI COJO COLA CULO FALO FETO
                     GETA GUEI GUEY JETA JOTO KACA KACO KAGA KAGO KAKA
                     KAKO KOGE KOGI KOJA KOJE KOJI KOJO KOLA KULO LILO
                     LOCA LOCO LOKA LOKO MAME MAMO MEAR MEAS MEON MIAR
                     MION MOCO MOKO MULA MULO NACA NACO ORIN PEDA PEDO
                     PENE PIPI PITO POPO PUTA PUTO QULO RATA ROBA ROBE
                     ROBO RUIN SENO TETA VACA VAGA VAGO VAKA VUEI VUEY
                     WUEI WUEY].freeze

    # O(1) lookup copies of the constants above (the public constants stay
    # as readable frozen Arrays).
    STATES = STATES_RENAPO.to_set.freeze
    WORDS  = NAME_ISSUES.to_set.freeze

    # Computes the RENAPO check digit (0-9) from the first 17 characters.
    #
    # Works on raw bytes: RENAPO's value table is contiguous in ASCII —
    # '0'-'9' = 48-57 (=> 0-9), 'A'-'N' = 65-78 (=> 10-23), 'O'-'Z' =
    # 79-90 (=> 25-36). The unused value 24 is Ñ's slot in the table;
    # Ñ never appears in a CURP (RENAPO substitutes it), so we only need
    # its offset (the -54 shift from 'O' on), not the character itself.
    # Returns nil for input shorter than 17 bytes.
    def self.check_digit(str)
      return nil if str.bytesize < 17

      sum = 0
      17.times do |i|
        b = str.getbyte(i)
        value = b < 58 ? b - 48 : (b < 79 ? b - 55 : b - 54)
        sum += value * (18 - i)
      end
      (10 - sum % 10) % 10
    end

    def self.valid?(curp)
      new(curp).valid?
    end

    def initialize(curp)
      @raw_input = curp.is_a?(String) ? curp.upcase : curp
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
      validate_check_digit
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

    def validate_check_digit
      expected = self.class.check_digit(@raw_input)
      return if expected && @raw_input[17].to_i == expected

      add_error(:check_digit,
                "Invalid check digit: expected '#{expected}', got '#{@raw_input[17]}'")
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
