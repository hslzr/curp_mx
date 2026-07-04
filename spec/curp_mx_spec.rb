# frozen_string_literal: true

RSpec.describe CurpMx do
  it 'has a version number' do
    expect(CurpMx::VERSION).not_to be nil
  end

  describe 'Validator class' do
    it 'defines 34 RENAPO states (32 states + CDMX alias + foreign-born)' do
      expect(CurpMx::Validator::STATES_RENAPO.length).to eq 34
    end

    it 'accepts NE (nacido en el extranjero) as a valid state' do
      # XEXX010101 is the RENAPO placeholder prefix for foreign-born.
      expect(CurpMx::Validator.new('XEXX010101HNEXXXA4').errors).not_to have_key(:state)
    end

    it 'defines 78 problematic name initials' do
      expect(CurpMx::Validator::NAME_ISSUES.length).to eq 78
    end

    # Synthetic, fully valid CURP (correct check digit included).
    #
    # BEBE900101HDFXXX07

    describe 'self.valid?' do
      it 'initializes and gets a boolean response' do
        response = CurpMx::Validator.valid?('BEBE900101HDFXXX07')

        expect(response).to be(true)
      end
    end

    describe 'check digit' do
      it 'accepts a CURP with the correct check digit' do
        expect(CurpMx::Validator.valid?('BEBE900101HDFXXX07')).to be true
      end

      it 'rejects a CURP with a wrong check digit' do
        validator = CurpMx::Validator.new('BEBE900101HDFXXX00')
        expect(validator.errors).to have_key(:check_digit)
        expect(validator.errors[:check_digit]).not_to be_empty
      end

      it 'computes the RENAPO check digit for the first 17 characters' do
        expect(CurpMx::Validator.check_digit('BEBE900101HDFXXX0')).to eq 7
      end
    end

    describe '#validate' do
      context 'with invalid CURP format' do
        subject { CurpMx::Validator.new('TOGG641309HJCRML99X') }

        it 'returns false' do
          expect(subject.errors).to have_key(:format)
          expect(subject.errors[:format]).to include('Invalid format')
        end

        it 'stops detecting anything else beyond that point' do
          # For this example, the birth_month is also wrong in the subject
          expect(subject.errors).not_to have_key('birth_month')
        end
      end

      context 'with invalid dates' do
        subject { CurpMx::Validator.new('TOGG641332HJCRML99') }

        it 'rejects it when DAY is out of range' do
          expect(subject.errors).to have_key(:birth_day)
          expect(subject.errors[:birth_day]).not_to be_empty
        end

        it 'rejects it when MONTH is out of range' do
          expect(subject.errors).to have_key(:birth_month)
          expect(subject.errors[:birth_month]).not_to be_empty
        end

        it 'rejects it when date does not exist' do
          # Setting subject's birth date as Feb 30th
          sample = CurpMx::Validator.new('TOGG640230HJCRML99')
          expect(sample.valid?).not_to be true
          expect(sample.errors).to have_key(:birth_date)
          expect(sample.errors[:birth_date]).not_to be_empty
        end
      end

      context 'with an invalid state' do
        # 'ZZ' is not a RENAPO state. Regression: this used to raise
        # NoMethodError because :state was never initialized.
        subject { CurpMx::Validator.new('TOGG641009HZZRML99') }

        it 'does not raise and reports a state error' do
          expect(subject.errors).to have_key(:state)
          expect(subject.errors[:state]).not_to be_empty
        end
      end

      context 'with problematic name initials' do
        # First four letters spell 'CACA'. Regression: this used to raise
        # NoMethodError because :problematic_name was never initialized.
        subject { CurpMx::Validator.new('CACA641009HJCRML99') }

        it 'does not raise and reports a problematic_name error' do
          expect(subject.errors).to have_key(:problematic_name)
          expect(subject.errors[:problematic_name]).not_to be_empty
        end
      end

      context 'with a post-2000 CURP (letter homoclave)' do
        # Born 2005; position 17 is a letter. Regression: the old
        # [0-9]{2} tail rejected every CURP issued from 2000 onward.
        subject { CurpMx::Validator.new('TOGG050101HJCRMLA2') }

        it 'accepts the format' do
          expect(subject.errors).not_to have_key(:format)
        end

        it 'is valid' do
          expect(subject.valid?).to be true
        end
      end

      context "with sex 'X'" do
        # Non-binary marker, valid since 2023.
        subject { CurpMx::Validator.new('TOGG641009XJCRML94') }

        it 'accepts it' do
          expect(subject.errors).not_to have_key(:format)
          expect(subject.valid?).to be true
        end
      end
    end
  end
end
