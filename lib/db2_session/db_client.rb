# frozen_string_literal: true

module Db2Session
  class DbClient < Db2Query::DbClient
    def initialize(config, userid, password)
      @dsn = config[:dsn]
      @idle_time_limit = config[:idle] || 5
      define_authenticated_client(userid, password)
      @client = authenticated_client
      @last_transaction = Time.now
    end

    def define_authenticated_client(userid, password)
      singleton_class.define_method(:authenticated_client) do
        new_client(userid, password)
      end
    end

    def new_client(userid, password)
      ODBC.connect(dsn, userid, password).tap do |odbc_conn|
        odbc_conn.use_time = true
        odbc_conn.use_utc = is_utc?
      end
    rescue ::ODBC::Error => e
      raise Db2Query::ConnectionError.new(e.message)
    end

    def reconnect!
      disconnect!
      @client = authenticated_client
    end
  end
end
