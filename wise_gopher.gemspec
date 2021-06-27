# frozen_string_literal: true

require_relative "lib/wise_gopher/version"

Gem::Specification.new do |spec|
  spec.name          = "wise_gopher"
  spec.version       = WiseGopher::VERSION
  spec.authors       = ["PageHey"]
  spec.email         = ["pagehey@pm.me"]

  spec.summary       = "Encapsulate raw SQL queries and return results as plain Ruby objects, using ActiveRecord."
  spec.description   = <<~STR
    Instead of using `ActiveRecord::Base.connection.execute("some raw sql ...")`,
    use WiseGopher to delcare your queries as classes,
    ensure sql injection protection
    and retrieve results as plain Ruby object with dedicated class instead of raw values in hashes or arrays.
  STR
  spec.homepage              = "https://github.com/Pagehey/wise_gopher"
  spec.license               = "MIT"
  spec.required_ruby_version = ">= 2.5.0"

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/Pagehey/wise_gopher"
  spec.metadata["changelog_uri"]   = "https://github.com/Pagehey/wise_gopher/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 5", "< 7"

  spec.add_development_dependency "database_cleaner", "~> 1.5"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-doc"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.10"
  spec.add_development_dependency "rubocop", "~> 1.7"
  spec.add_development_dependency "rubocop-rake"
  spec.add_development_dependency "rubocop-rspec"
  spec.add_development_dependency "sqlite3"
end
