# frozen_string_literal: true

module Definitions
  class UserQueryDefinitions < Db2Query::Definitions
    def describe
      query_definition :authenticate! do |c|
        c.connected
      end
    end
  end
end
