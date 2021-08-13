# frozen_string_literal: true

module Definitions
  class ConnectionQueryDefinitions < Db2Query::Definitions
    def describe
      query_definition :status do |c|
        c.connected :boolean
      end
    end
  end
end
