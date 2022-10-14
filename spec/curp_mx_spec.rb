# frozen_string_literal: true

RSpec.describe CurpMx do
  it 'has a version number' do
    expect(CurpMx::VERSION).not_to be nil
  end

  it 'declares a Validator class' do
    expect(CurpMx::Validator).to be_a Class
  end

  describe 'Validator class' do
    it 'defines 33 RENAPO states' do
      expect(CurpMx::Validator::STATES_RENAPO.length).to eq 33
    end

    it 'defines 78 problematic name initials' do
      expect(CurpMx::Validator::NAME_ISSUES.length).to eq 78
    end

    # Sample persona I'll be using: Guillermo del Toro
    #
    # TOGG641009HJCRML99

    describe '#valid?' do
      context 'with invalid CURP format' do
        subject { CurpMx::Validator.new('TOGG641309HJCRML99X') }
        before { subject.valid? }

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
        before { subject.valid? }

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
    end
  end
end
