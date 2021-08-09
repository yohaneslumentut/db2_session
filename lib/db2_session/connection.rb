# frozen_string_literal: true

module Db2Session
  class Connection < Db2Query::Connection
    attr_reader :token_key, :userid

    def initialize(config, userid, password)
      super(config)
      @userid = userid
      singleton_class.define_method(:new_dbclient) do
        DbClient.new(config, userid, password)
      end
      with { |conn| true }
    end

    def create_connection_pool
      synchronize do
        return @connection_pool if @connection_pool
        @connection_pool = Pool.new(pool_config) { new_dbclient }
      end
    end
  end
end
