# WiseGopher

Why is the gopher wise ? Because it knows one should not use raw SQL with ActiveRecord without being mindful about security and performance !

This gem tries to solve some problems found when ActiveRecord query builder is not enough for the SQL you need to run and you have to use [`exec_query`](https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/DatabaseStatements.html#method-i-exec_query):

1. ActiveRecord doesn't make it easy to use bind parameters. It needs a lot of build up to pass arguments for your query.
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

TODO: Write usage instructions here

------

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pagehey/wise_gopher. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/pagehey/wise_gopher/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the WiseGopher project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/pagehey/wise_gopher/blob/master/CODE_OF_CONDUCT.md).
