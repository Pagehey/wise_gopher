# WiseGopher

Why is the gopher wise ? Because it knows one should not use raw SQL with ActiveRecord without being mindful about security and performance !

This gem tries to solve some problems found when you need to execute custom and/or complex SQL queries for which returned data doesn't match your ActiveRecord models:

1. ActiveRecord doesn't make it easy to use bind parameters with [`exec_query`](https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/DatabaseStatements.html#method-i-exec_query). It needs a lot of build up to pass arguments for your query.
2. The result of query is return as an array of hashes wich deprive us of good old OOP.
3. The column types are not always correctly retrieved by ActiveRecord, or sometimes you need a little more ruby treatment on the value before using it.

[This article](https://blog.saeloun.com/2019/10/28/bind-parameters-in-activerecord-sql-queries.html) describe the benefits of using bind parameters with ActiveRecord.
[This one](https://use-the-index-luke.com/sql/where-clause/bind-parameters) goes further on the subject.

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
> DISCLAIMER: for the sake of example, the queries presented here can be very simple and would obviously match an ActiveRecord model. For such queries I would of course highly recommend to use basic ActiveRecord.
---

To use WiseGopher you have to create a class to declare your query and its specifications. It could look like this:

```ruby
class PopularArticle < WiseGopher::Base
  query <<-SQL
    SELECT title, AVG(ratings.stars) AS average_rating, published_at, author_username
    FROM articles
    INNER JOIN ratings ON ratings.article_id = articles.id
    WHERE author_username = {{ username }}
    GROUP BY articles.id
    HAVING AVG(ratings.stars) > {{ mininum_rating }}
    ORDER BY averating_rating
  SQL
  
  param :minimum_rating, :integer
  param :username, :string, transform: :strip
  
  row do
    column :title, :string, transform: :capitalize
    column :average_rating, :float, transform: -> { round(2) }
    column :published_at, :datetime
    column :author_username, :string, as: :author
    
    def to_s
        "Article '#{title}' by #{author} is rated #{"%.2f" % average_rating}/5."
    end
  end
end
```

Which you would use this way:
```ruby
result = PopularArticle.execute_with(minimum_rating: 3, username: "PageHey ")
# => [#<PopularArticle::Row:0x0000560c37e9de48 @title="My first gem is out!", @average_rating=3.5 ...>, ...]
puts result.first
# => Article 'My first gem is out!' by PageHey is rated 3.50/5.
result.first.class
# => PopularArticle::Row
```

------

So, basically what you need to do is make your class inherits from `WiseGopher::Base` and provide your SQL with `query`. You can then declare what columns will be present in result with `column` in a block given to `row`.


If your query doesn't need any parameter like this one:
```ruby
class PopularArticle < WiseGopher::Base
    query "SELECT title FROM articles"
    
    row do
        column :title, :string
    end
end
```
You can simply get result with `execute`:
```ruby
PopularArticle.execute
```

If your query **does need** parameter like this one:
```ruby
class PopularArticle < WiseGopher::Base
    query <<-SQL
        SELECT title FROM articles
        WHERE author = {{ author_name }} AND published_at > {{ published_after }}
    SQL
    
    param :author_name, :string
    param :published_after, :date
    
    row do
        column :title, :string
    end
end
```
You should declare the params with `param` so you can pass the parameters as a hash to `execute_with`:
```ruby
PopularArticle.execute_with(author_name: "PageHey", published_after: Date.today - 1.month)
```

If any parameter is missing or if you call `execute` for a class that needs some, it will raise `WiseGopher::ArgumentError`.

Before query execution, the placeholders will be replaced with the standard `?` placeholder or with the `$1`, `$2` ... numbered placeholders for PostgreSQL database.

To declare the column in result, you should use `row` and pass it a block. Calling this method will create a `Row` class nested into your query class. The block will be then executed in `Row` class context. In this context you can use `column` but also define method, include module, basicaly write any code you would find in a class delacration.

The goal of this syntax is to gather in the same file the inputs and outputs of the query while keeping dedicated classes for each subject.
You can provide a custom class to `row` if you prefer. If you still pass the block to the method, the `WiseGopher::Row` module will be included in the class before evaluating it, so you can have this syntax:
```ruby
# /my_custom_row.rb
class MyCustomRow
    def some_custom_method
        # [...]
    end
end

# /my_query_class.rb
class MyQueryClass < WiseGopher::Base
    query "SELECT title FROM articles"
    
    row MyCustomRow do
        column :title, :string
    end
end
```

**If you don't give any block to `row`, make sure you include `WiseGopher::Row` in your class.**

------
## Raw params
If you need to dynamically interpolate raw SQL in your query, you can use `raw_param`. The value passed with `execute_with` will be interpolated in the base query before inserting the other params.
```ruby
class AnnualReport < WiseGopher::Base
    query <<-SQL
        SELECT month, revenue
        FROM heavy_computations
        WHERE employee_id = {{ id }}
        {{ order_by }}
    SQL
    
    param :id, :integer
    
    raw_param :order_by
end

AnnualReport.execute_with(id: 1, order_by: "ORDER BY id ASC")
```
executed query will look like this:
```SQL
SELECT month, revenue
FROM heavy_computations
WHERE employee_id = ?
ORDER BY id ASC
```
By default, `raw_param` is required but you can pass `optional: true`. You can then omit the param and the placeholder will be remove for this query instance.
```ruby
AnnualReport.execute_with(id: 1, order_by: "ORDER BY id ASC")
```
```SQL
SELECT month, revenue
FROM heavy_computations
WHERE employee_id = ?
```

You can also provide _prefix_ and/or _suffix_ to `raw_param` to make the `raw_param` clearer and the argument lighter.
```ruby
class AnnualReport < WiseGopher::Base
    query <<-SQL
        SELECT month, revenue
        FROM heavy_computations
        WHERE employee_id = {{ id }}
        {{ order_by }}
    SQL
    
    param :id, :integer
    
    raw_param :order_by, prefix: "ORDER BY ", suffix: " ASC" # note the spacings
end
AnnualReport.execute_with(id: 1, order_by: "id")
```
Finally, a default option is also supported, thus making the param optional:
```ruby
class AnnualReport < WiseGopher::Base
    query <<-SQL
        SELECT month, revenue
        FROM heavy_computations
        WHERE employee_id = {{ id }}
        {{ order_by }}
    SQL
    
    param :id, :integer
    
    raw_param :order_by, prefix: " ORDER BY ", suffix: " ASC ", default: "id"
end
AnnualReport.execute_with(id: 1)
```
executed query:
```SQL
SELECT month, revenue
FROM heavy_computations
WHERE employee_id = ?
ORDER BY id ASC
```

------
## Methods documentation
### WiseGopher::Base (class)
#### ::param
```ruby
param(name, type, transform: nil)
```

Argument | Required | Descrition
------------ | ------------- | ------------- 
name | true | The name of the parameter as written in the `{{ placeholder }}`
type | true | The type of the column. It can be any type registred as ActiveRecord::Type. Including yours
transform: | false | `Proc` or `Symbol`. An operation that will be call before creating the bind parameter when you call `execute_with`.

#### ::raw_param
```ruby
raw_param(name, prefix: nil, suffix: nil, default: nil, optional: false)
```

Argument | Required | Descrition
------------ | ------------- | ------------- 
name | true | The name of the parameter as written in the `{{ placeholder }}`
prefix: | false | The string to be inserted **before** the value passed as argument. No spaces will be added around to allow maximum customization.
suffix: | false | The string to be inserted **after** the value passed as argument. No spaces will be added around to allow maximum customization.
default: | false | The default value used if none is passed when calling the query
optional: | false | an empty string will be inserted in place of the placeholder if neither argument or default is provided.

###  WiseGopher::Row (module)
#### ::column
```ruby
column(name, type, transform: nil, as: nil)
```

Argument | Required | Descrition
------------ | ------------- | ------------- 
name | true | The name (or alias) of the SQL column as written in the SELECT statement
type | true | The type of the column. It can be any type registred as ActiveRecord::Type. Including yours
transform: | false | `Proc` or `Symbol`. An operation that will be call on value while initializing the row object (See tips below).
as: | false | The name of the getter you want on the row instance for this column (getter with original name won't be created!)

------
## Tips
#### transform: argument as proc
If you provide a proc to the `transform:` argument (either on `column` or `param`), you can expect one argument or none. If one argument is expected the value of the param or column will be passed.

#### Prepare query for later execution
You can prepare the query with param without executing it by simply calling `new` on your class and providing the params an later call `execute`.
```ruby
class PopularArticle < WiseGopher::Base
    query <<-SQL
        SELECT title FROM articles
        WHERE published_at > {{ published_after }}
    SQL
    
    param :published_after, :date
    
    row do
        column :title, :string
    end
end
last_month_articles = PopularArticle.new(published_after: Date.today - 1.month)
# [...]
last_month_articles.execute # => [#<PopularArticle::Row:0x0000560c37e9de48 ...>]
```

#### Ignore column in result
If for some reason, you have a column in your result that you don't want to retrieve on the row instances, you can use `ignore`.
```ruby
class MyQuery < WiseGopher::Base
    query "SELECT title, rating FROM articles"
    
    row do
        column :title, :string
        ignore :rating
    end
end

MyQuery.execute # => no error raised
```

#### Array of value as parameter
You can pass an array as parameter value. The will then make a comma separated list of placeholders and pass the arguments as many bind parameters.
```ruby
class MyQuery < WiseGopher::Base
    query "SELECT title FROM articles WHERE rating in ({{ ratings }})"
    
    param :ratings, :integer
    
    row do
        column :title, :string
    end
end

MyQuery.execute_with(ratings: [1, 2])
# query will be "SELECT title FROM articles WHERE rating in (?, ?)"
```

#### Classic param in raw_param
As the raw_params are interpolated before the classic params, you can have placeholders in them:
```ruby
class MyQuery < WiseGopher::Base
    query <<-SQL
        SELECT title FROM articles
        WHERE rating > {{ min_rating }}
        {{ or_condition }}
    SQL
    
    param :min_rating, :integer
    
    raw_param :or_condition, prefix: " OR "
    
    row do
        column :title, :string
    end
end

MyQuery.execute_with(min_rating: 1, or_condition: "rating = {{ min_rating }}")
# query will be "SELECT title FROM articles WHERE rating > ? OR rating = ?"
```

------

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pagehey/wise_gopher. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/pagehey/wise_gopher/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the WiseGopher project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/pagehey/wise_gopher/blob/master/CODE_OF_CONDUCT.md).
