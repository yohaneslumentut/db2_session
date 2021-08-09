# frozen_string_literal: true

module Db2Session
  class Engine < ::Rails::Engine
    isolate_namespace Db2Session
    config.generators.api_only = true
  end
end
