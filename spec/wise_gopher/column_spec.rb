# frozen_string_literal: true

RSpec.describe WiseGopher::Column do # rubocop:disable Metrics/BlockLength
  describe "#cast" do
    context "when transform is not given" do
      let(:string_column)  { described_class.new(:title, :string) }
      let(:integer_column) { described_class.new(:rating, :integer) }

      it "casts a value according to column type" do
        expect(string_column.cast(1)).to    eq("1")
        expect(integer_column.cast("1")).to  eq(1)
        expect(integer_column.cast(3.14)).to eq(3)
      end
    end

    context "when tranform is given" do
      context "when transform is given as method_name" do
        let(:column) { described_class.new(:title, :string, after_cast: :capitalize!) }

        it "casts a value according to column type and transform method" do
          expect(column.cast("gandalf")).to be_a(String)
          expect(column.cast("gandalf")).to eq("Gandalf")
        end
      end

      context "when transform is given as a block (with arity 0)" do
        let(:column) { described_class.new(:title, :string, after_cast: -> { capitalize! }) }

        it "casts a value according to column type and transform method" do
          expect(column.cast("gandalf")).to be_a(String)
          expect(column.cast("gandalf")).to eq("Gandalf")
        end
      end

      context "when transform is given as a block (with arity 1)" do
        let(:column) { described_class.new(:title, :string, after_cast: ->(value) { value.capitalize! }) }

        it "casts a value according to column type and transform method" do
          expect(column.cast("gandalf")).to be_a(String)
          expect(column.cast("gandalf")).to eq("Gandalf")
        end
      end
    end
  end
end
