# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

RSpec.describe WiseGopher::Column do
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
        let(:column) { described_class.new(:title, :string, transform: :capitalize) }

        it "casts a value according to column type and transform method" do
          expect(column.cast("gandalf")).to be_a(String)
          expect(column.cast("gandalf")).to eq("Gandalf")
        end
      end

      context "when transform is given as a block (with arity 0)" do
        let(:column) { described_class.new(:title, :string, transform: -> { capitalize }) }

        it "casts a value according to column type and transform method" do
          expect(column.cast("gandalf")).to be_a(String)
          expect(column.cast("gandalf")).to eq("Gandalf")
        end
      end

      context "when transform is given as a block (with arity 1)" do
        let(:column) { described_class.new(:title, :string, transform: ->(value) { value.capitalize }) }

        it "casts a value according to column type and transform method" do
          expect(column.cast("gandalf")).to be_a(String)
          expect(column.cast("gandalf")).to eq("Gandalf")
        end
      end
    end
  end

  describe "::define_getter" do
    let(:row_class)        { Class.new { include WiseGopher::Row } }
    let(:row)              { row_class.new({ "title" => "Dragons are real!", "rating" => "9999" }) }
    let(:string_column)    { described_class.new(:title, :string) }
    let(:integer_column)   { described_class.new(:rating, :integer, as: :how_much_vegeta?) }

    before do
      string_column.define_getter(row_class)
      integer_column.define_getter(row_class)

      row_class.columns[string_column.name]  = string_column
      row_class.columns[integer_column.name] = integer_column
    end

    it "creates a getter on row class" do
      expect(row_class.instance_methods(false)).to include(:title)
      expect(row_class.instance_methods(false)).to include(:how_much_vegeta?)
      expect(row.title).to                         eq("Dragons are real!")
      expect(row.how_much_vegeta?).to              be > 9000
    end
  end
end

# rubocop:enable Metrics/BlockLength
