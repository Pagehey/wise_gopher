# frozen_string_literal: true

RSpec.describe WiseGopher::Base do # rubocop:disable Metrics/BlockLength
  describe "#execute" do # rubocop:disable Metrics/BlockLength
    context "when result contains more columns than declared" do
      let(:query_class) do
        query_class = Class.new(WiseGopher::Base) do
          query <<-SQL
            SELECT title, rating FROM articles
          SQL

          row do
            column :title, :string
          end
        end

        stub_const("ArticleQuery", query_class)
      end

      let(:result) { query_class.execute }

      before do
        # title, content, rating, published_at
        create_article("My first article", "Some stuff about SQL", 3, DateTime.new(2021, 7, 26))
      end

      it "raises an error if result contains undeclared columns" do
        expect { result }.to raise_error(WiseGopher::UndeclaredColumns)
        # which one ?
      end
    end

    context "when row is not declared" do
      let(:query_class) do
        query_class = Class.new(WiseGopher::Base) do
          query <<-SQL
            SELECT title, rating FROM articles
          SQL
        end

        stub_const("ArticleQuery", query_class)
      end

      let(:result) { query_class.execute }

      before do
        # title, content, rating, published_at
        create_article("My first article", "Some stuff about SQL", 3, DateTime.new(2021, 7, 26))
      end

      it "raises an error" do
        expect { result }.to raise_error(WiseGopher::RowClassIsMissing)
        # which one ?
      end
    end

    context "when class is correctly declared" do # rubocop:disable Metrics/BlockLength
      let(:query_class) do
        query_class = Class.new(WiseGopher::Base) do
          query <<-SQL
            SELECT title, rating FROM articles
          SQL

          row do
            column :title,  :string
            column :rating, :integer
          end
        end

        stub_const("ArticleQuery", query_class)
      end

      let(:result) { query_class.execute }

      before do
        # title, content, rating, published_at
        create_article("My first article", "Some stuff about SQL", 3, DateTime.new(2021, 7, 26))
        create_article(
          "Why someone can not simply walk into Mordor",
          "Beware of the Orcs!",
          5,
          DateTime.new(1954, 7, 29)
        )
      end

      it "returns an Array of row objects" do
        expect(result.each).to   be_a(ArticleQuery::Row)
        expect(result).to        be_a(Array)
        expect(result.length).to eq(2)
      end
    end
  end
end
