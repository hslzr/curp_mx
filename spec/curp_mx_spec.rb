RSpec.describe CurpMx do
  it "has a version number" do
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
      expect(CurpMx::Validator::ISSUES.length).to eq 78
    end

    describe '#valid?' do
      context 'with valid CURP format' do
        it 'accepts the format as valid' do
          # For simplicity's sake, everything but the format will be wrong
          curp = "DEGE881818HASNNN11"
          val = CurpMx::Validator.new(curp)
          expect(val.valid?).to be false
          expect(val.errors).not_to include(:format)
        end
      end
    end
  end
end
