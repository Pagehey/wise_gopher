# WiseGopher

Why is the gopher wise ? Because it knows one should not use raw SQL with ActiveRecord without being mindful about security and performance !

This gem tries to solve some problems found when you need to execute custom and/or complex SQL queries for which returned data doesn't match your ActiveRecord models:

1. ActiveRecord doesn't make it easy to use bind parameters with [`exec_query`](https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/DatabaseStatements.html#method-i-exec_query). It needs a lot of build up to pass arguments for your query.
2. The result of query is return as an array of hashes wich deprive us of good old OOP.
3. The column types are not always correctly retrieved by ActiveRecord, or sometimes you need a little more ruby treatment on the value before using it.

[This article](https://blog.saeloun.com/2019/10/28/bind-parameters-in-activerecord-sql-queries.html) describe the benefits of using bind parameters with ActiveRecord.

The basic idea of this gem is to provide you a way to declare what your query needs as input, what columns it returns and their type. In returns it will allow you to retrieve the rows from result as an array of plain Ruby objects. It will also dynamically creates a class for the row objects that you can customize or can provide it yourself.

NB : This is my very first gem, any suggestions, feedbacks or bug reports are very welcome ! 😃

------

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'wise_gopher'
```

And then execute:

    bundle install

Or install it yourself as:

    gem install wise_gopher

------

## Usage
DISCLAIMER: for the sake of example the queries presented here are simple and would obviously match an ActiveRecord model. For such queries I would of course highly recommend to use basic ActiveRecord.

To use WiseGopher you have to create a class to declare your query and its specifications. It could look like this:

```ruby
class PopularArticle < WiseGopher::Base
  query <<-SQL
    SELECT title, AVG(ratings.stars) AS average_rating, published_at, author_username
    FROM articles
    INNER JOIN ratings ON ratings.article_id = articles.id
    GROUP BY articles.id
    HAVING average_rating > {{ mininum_rating }}
  SQL
  
  param :minimum_rating, :integer
  
  row do
    column :title, :string, transform: :capitalize
    column :average_rating, :float, -> { round(2) }
    column :published_at, :datetime
    column :author_username, as: :author
    
    def to_s
        "Article '#{title}' by #{author} is rated #{average_rating}/5."
    end
  end
end
```

------

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pagehey/wise_gopher. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/pagehey/wise_gopher/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the WiseGopher project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/pagehey/wise_gopher/blob/master/CODE_OF_CONDUCT.md).
