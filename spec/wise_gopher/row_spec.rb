# frozen_string_literal: true

RSpec.describe WiseGopher::Row do # rubocop:disable Metrics/BlockLength
  describe "::columns" do
    let(:row_class) { Class.new.include described_class }
    let(:columns)   { row_class.columns }

    before do
      row_class.column :title,  :string, transform: :capitalize
      row_class.column :rating, :integer, as: :average_rating
    end

    it "returns all registered columns" do
      expect(columns.length).to          eq(2)
      expect(columns["title"].name).to   eq("title")
      expect(columns["title"].alias).to  eq("title")
      expect(columns["rating"].name).to  eq("rating")
      expect(columns["rating"].alias).to eq("average_rating")
    end

    it "returns registed columns as Column objects" do
      expect(columns["title"]).to be_a(WiseGopher::Column)
    end
  end

  describe "::column" do
    let(:row_class) { Class.new.include described_class }
    let(:column)    { row_class.instance_variable_get("@columns").values.first }

    before do
      row_class.column :title, :string, as: :capitalized_title, transform: :capitalize
    end

    it "registers a column expected in result" do
      expect(row_class.instance_variable_get("@columns").length).to eq(1)

      expect(column).to           be_a(WiseGopher::Column)
      expect(column.name).to      eq("title")
      expect(column.alias).to     eq("capitalized_title")
      expect(column.type.type).to eq(:string)
    end
  end

  describe "::ignore" do
    let(:row_class) { Class.new.include described_class }

    before do
      row_class.ignore(:rating)
    end

    it "adds column to ignore in result" do
      expect(row_class.ignored_columns).to eq(["rating"])
    end
  end

  describe "::new" do
    let(:row_class) { Class.new.include described_class }
    let(:row)       { row_class.new({ "title" => "Dragons are real!", "rating" => "9999" }) }

    before do
      row_class.column(:title,  :string)
      row_class.column(:rating, :integer, as: :how_much_vegeta?)
    end

    it "returns a row instance with columns as getters" do
      expect(row.title).to            eq("Dragons are real!")
      expect(row.how_much_vegeta?).to be > 9000
    end
  end
end
