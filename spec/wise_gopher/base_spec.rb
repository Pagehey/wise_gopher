# frozen_string_literal: true

RSpec.describe WiseGopher::Base do # rubocop:disable Metrics/BlockLength
  describe "::query" do
    let(:query) do
      <<-SQL
        SELECT title, rating FROM articles
      SQL
    end

    let(:query_class) do
      query_class = Class.new(described_class)

      stub_const("ArticleQuery", query_class)
    end

    before { query_class.query query }

    it "registers the query sql" do
      query_const = query_class::QUERY

      expect(query_const).to         eq(query)
      expect(query_const.frozen?).to be true
    end
  end

  describe "::param" do
    let(:query_class) do
      query_class = Class.new(described_class)

      stub_const("ArticleQuery", query_class)
    end

    before { query_class.param(:title, :string) }

    it "registers a query param with the given arguments" do
      params_variable = query_class.instance_variable_get("@params")

      expect(params_variable.length).to                 eq(1)
      expect(params_variable.values.first).to           be_a(WiseGopher::Param)
      expect(params_variable.values.first.name).to      eq("title")
      expect(params_variable.values.first.type.type).to eq(:string)
    end
  end

  describe "::execute" do # rubocop:disable Metrics/BlockLength
    context "when result contains more columns than declared" do
      let(:query_class) do
        query_class = Class.new(described_class) do
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

      it "raises an error" do
        expect { result }.to raise_error(WiseGopher::UndeclaredColumns, /rating/)
      end
    end

    context "when result contains more columns than declared but column are ignored" do
      let(:query_class) do
        query_class = Class.new(described_class) do
          query <<-SQL
            SELECT title, rating FROM articles
          SQL

          row do
            column :title, :string
            ignore :rating
          end
        end

        stub_const("ArticleQuery", query_class)
      end

      let(:result) { query_class.execute }

      before do
        # title, content, rating, published_at
        create_article("My first article", "Some stuff about SQL", 3, DateTime.new(2021, 7, 26))
      end

      it "raises an error" do
        expect { result }.not_to raise_error
      end
    end

    context "when row is not declared" do
      let(:query_class) do
        query_class = Class.new(described_class) do
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
        query_class = Class.new(described_class) do
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
        expect(
          result.all? { |obj| obj.is_a? ArticleQuery::Row }
        ).to                     be true
        expect(result).to        be_a(Array)
        expect(result.length).to eq(2)
      end
    end
  end

  describe "::execute_with" do # rubocop:disable Metrics/BlockLength
    let(:query_class) do
      query_class = Class.new(described_class) do
        query <<-SQL
          SELECT title, rating FROM articles
          WHERE title = {{ title }}
        SQL

        param :title, :string

        row do
          column :title,  :string
          column :rating, :integer
        end
      end

      stub_const("ArticleQuery", query_class)
    end

    context "when inputs are missing" do
      let(:result) { query_class.execute_with({}) }

      it "raises an error" do
        expect { result }.to raise_error(WiseGopher::ArgumentError, /title/)
      end
    end

    context "when all inputs are given" do
      let(:result) { query_class.execute_with({ title: "My first article" }) }

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

      it "returns an Array of expected row objects" do
        expect(result.length).to          eq(1)
        expect(result.first.title).not_to eq("Why someone can not simply walk into Mordor")
        expect(result.first.title).to     eq("My first article")
        expect(result.first.rating).to    eq(3)
      end
    end
  end

  describe ".prepare_query" do # rubocop:disable Metrics/BlockLength
    let(:query_class) do
      query_class = Class.new(described_class) do
        query <<-SQL
          SELECT title, rating FROM articles
          WHERE title = {{ title }}
          AND id IN ({{ id }})
        SQL

        param :title, :string
        param :id,    :integer
      end

      stub_const("ArticleQuery", query_class)
    end

    let(:query_instance) do
      query_class.new(
        title: "Potatoes can produce more energy than nuclear fission!",
        id:    [1, 2]
      )
    end

    context "when RDBMS is PostgreSQL" do
      before do
        stub_const("ActiveRecord::ConnectionAdapters::SQLite3Adapter::ADAPTER_NAME", "PostgreSQL")

        query_instance.prepare_query
      end

      it "replaces param placeholders with numbered binds" do
        query = query_instance.instance_variable_get("@query")

        expect(query.squish).to eq <<-SQL.squish
          SELECT title, rating FROM articles
          WHERE title = $1
          AND id IN ($2, $3)
        SQL
      end
    end

    context "with every other RDBMS" do
      before { query_instance.prepare_query }

      it "replaces param placeholders with bind symbols" do
        query = query_instance.instance_variable_get("@query")

        expect(query.squish).to eq <<-SQL.squish
          SELECT title, rating FROM articles
          WHERE title = ?
          AND id IN (?, ?)
        SQL
      end
    end
  end
end
