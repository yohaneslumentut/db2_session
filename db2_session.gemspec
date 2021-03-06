# frozen_string_literal: true

require_relative "lib/db2_session/version"

Gem::Specification.new do |spec|
  spec.name        = "db2_session"
  spec.version     = Db2Session::VERSION
  spec.authors     = ["yohanes_o_lumentut"]
  spec.email       = ["yohanes.lumentut@gmail.com"]
  spec.homepage    = "https://github.com/yohaneslumentut/db2_session"
  spec.summary     = "Rails Db2 API session manager plugin"
  spec.description = "A Rails 5 & Rails 6 plugin for handling Db2 API request by using JWT token."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/yohaneslumentut/db2_session"
  spec.metadata["changelog_uri"] = "https://github.com/yohaneslumentut/db2_session"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  # spec.add_dependency "rails", "~> 6.1.4"
  spec.add_development_dependency "tty-progressbar"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "rubocop-performance"
  spec.add_development_dependency "rubocop-rails"
  spec.add_development_dependency "faker"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "rails"

  spec.add_dependency "db2_query", "~> 0.3.2"
  spec.add_dependency "jwt"
  spec.add_dependency "securerandom"
end
