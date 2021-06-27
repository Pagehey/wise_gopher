# frozen_string_literal: true

RSpec.describe WiseGopher::Param do # rubocop:disable Metrics/BlockLength
  describe "#build_bind" do
    let(:param) { described_class.new(:published_at, :datetime) }
    let(:bind)  { param.build_bind(DateTime.new(2021, 1, 1, 10, 30)) }

    it "returns an ActiveRecord::Relation::QueryAttribute" do
      expect(bind).to be_a ActiveRecord::Relation::QueryAttribute
    end

    it "has correct name and type" do
      expect(bind.name).to      eq("published_at")
      expect(bind.type).to      be_a ActiveModel::Type::Value
      expect(bind.type.type).to eq(:datetime)
    end

    context "when no transform is given" do
      let(:param) { described_class.new(:rating, :integer) }
      let(:bind)  { param.build_bind("3.14") }

      it "has correct value" do
        expect(bind.value_for_database).to eq(3)
      end
    end

    context "when transform is given" do
      let(:param) { described_class.new(:rating, :integer, ->(rating) { rating.clamp(0, 10) }) }
      let(:bind)  { param.build_bind(314) }

      it "has correct value" do
        expect(bind.value_for_database).to eq(10)
      end
    end
  end
end
