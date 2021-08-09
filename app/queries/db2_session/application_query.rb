# frozen_string_literal: true

module Db2Session
  class ApplicationQuery
    include Db2Query::Config
    include Db2Query::Helper
    include Db2Query::DbConnection
    include Db2Query::FieldType
    include Db2Query::Core

    def self.establish_connection
      load_database_configurations
    end

    def self.connection
      Thread.current[:connection]
    end
  end
end
