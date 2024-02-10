module CurpMx
  class Parser < Parslet::Parser
    rule(:father_surname) { match('[A-Z]').repeat(2, 2) }
    rule(:mother_surname) { match('[A-Z]').repeat(1, 1) }
    rule(:name) { match('[A-Z]').repeat(1) }
    rule(:birth_date) { match('[0-9]').repeat(2, 2) }
    rule(:birth_month) { match('[A-Z]').repeat(1, 1) }
    rule(:birth_year) { match('[0-9]').repeat(2, 2) })
    rule(:sex) { match('(H|M)').repeat(1, 1) }
    rule(:state) { match('[A-Z]').repeat(2, 2) }
    rule(:father_surname_consonant) { match('[A-Z]').repeat(1, 1) }
    rule(:mother_surname_consonant) { match('[A-Z]').repeat(1, 1) }
    rule(:name_consonant) { match('[A-Z]').repeat(1, 1) }
    rule(:homoclave) { match('[0-9]').repeat(2, 2) }
  end
end
