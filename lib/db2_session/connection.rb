# frozen_string_literal: true

module Db2Session
  class Connection < Db2Query::Connection
    attr_accessor :trx_time, :userid

    def initialize(config, userid, password)
      super(config)
      @userid = userid
      singleton_class.define_method(:new_dbclient) do
        DbClient.new(config, userid, password)
      end
      verify_db_connection
    end

    def create_connection_pool
      synchronize do
        return @connection_pool if @connection_pool
        @connection_pool = Pool.new(pool_config) { new_dbclient }
      end
    end

    private
      def verify_db_connection
        with { |conn| true }
      end
  end
end
