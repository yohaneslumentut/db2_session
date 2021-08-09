# frozen_string_literal: true

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"
require_relative "../test/dummy/config/environment"
require "rails/test_help"

env_file = "#{Dir.pwd}/test/local_env.yml"

YAML.load(File.open(env_file)).each do |key, value|
  ENV[key.to_s] = value
end if File.exists?(env_file)
