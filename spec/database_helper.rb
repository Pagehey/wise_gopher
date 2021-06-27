# frozen_string_literal: true

# Helper to ease database manipulation and connection
module DatabaseHelper
  private

  def connection
    @connection ||= begin
      establish_connection

      create_articles_table

      ActiveRecord::Base.connection
    end
  end

  def establish_connection
    ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"
  end

  def create_articles_table
    ActiveRecord::Migration.verbose = false

    ActiveRecord::Migration.create_table :articles do |t|
      t.string   :title
      t.string   :content
      t.integer  :rating
      t.datetime :published_at
    end
  end

  def create_article(title, content, rating, published_at)
    # https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/DatabaseStatements.html#method-i-insert

    id = connection.insert(
      "INSERT INTO articles (title, content, rating, published_at) VALUES (?, ?, ?, ?)",
      nil, nil, nil, nil, # name = nil, pk = nil, id_value = nil, sequence_name = nil
      [title, content, rating, published_at]
    )
    connection.execute("SELECT * FROM articles WHERE id = #{id} LIMIT 1")
  end
end
