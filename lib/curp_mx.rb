# frozen_string_literal: true

require 'date'

module CurpMx
  VERSION = '0.1.0'

  # Used to validate a CURPs format and a few data points in it
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
                (?<key>[0-9]{2})\z/x.freeze

    # States' initials as listed in
    # Registro Nacional de Población (RENAPO)
    STATES_RENAPO = %w[AS BC BS CC CS CH CL CM DF CX DG GT GR HG JC MC MN MS
                       NT NL OC PL QT QR SP SL SR TC TS TL VZ YN ZS].freeze

    # Problematic name initials
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
        @errors[:format] ||= []
        @errors[:format] << 'Invalid format'
        return false
      end

      validate_state
      validate_name_initials
      validate_birth_date
      validate_date_exists
    end

    private

    def validate_state
      return if STATES_RENAPO.include? @md[:state]

      @errors[:state] << "Invalid state: '#{@md[:state]}'"
    end

    def validate_name_initials
      return unless NAME_ISSUES.include?(name_initials)

      @errors[:name] << "Problematic name initials: '#{name_initials}'"
    end

    def validate_birth_date
      validate_birth_day
      validate_birth_month
    end

    def validate_birth_day
      birth_day = @md[:birth_day].to_i
      return unless birth_day <= 0 || birth_day > 31

      @errors[:birth_day] ||= []
      @errors[:birth_day] << "Invalid birth day: '#{@md[:birth_day]}'"
    end

    def validate_birth_month
      birth_month = @md[:birth_month].to_i
      return unless birth_month <= 0 || birth_month > 12

      @errors[:birth_month] ||= []
      @errors[:birth_month] << "Invalid birth month: '#{@md[:birth_month]}'"
    end

    def validate_date_exists
      date_str = "#{@md[:birth_year]}-#{@md[:birth_month]}-#{@md[:birth_day]}"
      return if valid_date?(date_str)

      @errors[:birth_date] ||= []
      @errors[:birth_date] << "Invalid birth date (YYYY-mm-dd): #{date_str}"
    end

    def name_initials
      [@md[:father_initial], @md[:mother_initial], @md[:name_initial]].join
    end

    def valid_date?(date_str)
      # Inner works: Date.valid_date? 2020, 7, 21
      Date.valid_date?(*date_str.split('-').map(&:to_i))
    end
  end
end
