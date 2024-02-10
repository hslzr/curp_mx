require "parslet"

module CurpMx
  class Parser < Parslet::Parser
    rule(:father_surname) { match('[A-Z]').repeat(2, 2) }
    rule(:mother_surname) { match('[A-Z]').repeat(1, 1) }
    rule(:name) { match('[A-Z]').repeat(1) }
    rule(:birth_date) { match('[0-9]').repeat(2, 2) }
    rule(:birth_month) { match('[0-9]').repeat(2, 2) }
    rule(:birth_year) { match('[0-9]').repeat(2, 2) }
    rule(:sex) { match('(H|M)').repeat(1, 1) }
    rule(:state) { match('[A-Z]').repeat(2, 2) }
    rule(:father_surname_consonant) { match('[A-Z]').repeat(1, 1) }
    rule(:mother_surname_consonant) { match('[A-Z]').repeat(1, 1) }
    rule(:name_consonant) { match('[A-Z]').repeat(1, 1) }
    rule(:homoclave) { match('[0-9]').repeat(2, 2) }

    rule(:curp) do
      father_surname.as(:father_surname) >>
        mother_surname.as(:mother_surname) >>
        name.as(:name) >>
        birth_date.as(:birth_date) >>
        birth_month.as(:birth_month) >>
        birth_year.as(:birth_year) >>
        sex.as(:sex) >>
        state.as(:state) >>
        father_surname_consonant.as(:father_surname_consonant) >>
        mother_surname_consonant.as(:mother_surname_consonant) >>
        name_consonant.as(:name_consonant) >>
        homoclave.as(:homoclave)
    end

    root :curp
  end
end
