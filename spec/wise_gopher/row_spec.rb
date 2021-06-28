# frozen_string_literal: true

RSpec.describe WiseGopher::Row do # rubocop:disable Metrics/BlockLength
  # describe "Row class" do
  #   let(:query_class) do
  #     query_class = Class.new(WiseGopher::Base) do
  #       query <<-SQL
  #         SELECT title FROM articles
  #       SQL

  #       row do
  #         column :title, :stirng
  #       end
  #     end

  #     stub_const("ArticleQuery", query_class)
  #   end

  #   it "is defined at query class creation" do
  #     expect(defined? ArticleQuery::Row).to be_truthy
  #   end
  # end

  # describe "Row instance" do
  #   let(:query_class) do
  #     query_class = Class.new(WiseGopher::Base) do
  #       query <<-SQL
  #         SELECT title, rating FROM articles
  #       SQL

  #       row do
  #         column :title,  :string
  #         column :rating, :integer
  #       end
  #     end

  #     stub_const("ArticleQuery", query_class)
  #   end

  #   let(:row) { query_class.execute.first }

  #   before do
  #     # title, content, rating, published_at
  #     create_article("Why someone can not simply walk into Mordor", "Beware of the Orcs!", 5, DateTime.new(1954, 7, 29))
  #   end

  #   it "be returned as result objects" do
  #     expect(row).to be_a(ArticleQuery::Row)
  #   end

  #   it "has getter for each declared column" do
  #     expect(row.title).to  eq("Why someone can not simply walk into Mordor")
  #     expect(row.rating).to eq(5)
  #   end
  # end

  describe "::columns" do
    let(:row_class) do
      Class.new { include WiseGopher::Row }
    end

    let(:columns) { row_class.columns }

    before do
      row_class.column :title,  :string, after_cast: :capitalize!
      row_class.column :rating, :integer, as: :average_rating
    end

    it "returns all registered columns" do
      expect(columns.length).to          eq(2)
      expect(columns['title'].name).to   eq("title")
      expect(columns['title'].alias).to  eq("title")
      expect(columns['rating'].name).to  eq("rating")
      expect(columns['rating'].alias).to eq("average_rating")
    end

    it "returns registed columns as Column objects" do
      expect(columns['title']).to be_a(WiseGopher::Column)
    end
  end

  describe "::column" do
    let(:row_class) do
      Class.new { include WiseGopher::Row }
    end

    let(:column) { row_class.instance_variable_get("@columns").values.first }

    before do
      row_class.column :title, :string, as: :capitalized_title, after_cast: :capitalize!
    end

    it "registers a column expected in result" do
      expect(row_class.instance_variable_get("@columns").length).to eq(1)

      expect(column).to           be_a(WiseGopher::Column)
      expect(column.name).to      eq("title")
      expect(column.alias).to     eq("capitalized_title")
      expect(column.type.type).to eq(:string)
    end
  end

  describe "::new" do
    before do
      row_class.column(:title,  :string)
      row_class.column(:rating, :integer, as: :how_much_vegeta?)
    end

    let(:row_class) do
      Class.new { include WiseGopher::Row }
    end

    let(:row) { row_class.new({ "title" => "Dragons are real!", "rating" => "9999" }) }

    it "returns a row instance with columns as getters" do
      expect(row.title).to            eq("Dragons are real!")
      expect(row.how_much_vegeta?).to be > 9000
    end
  end
end
