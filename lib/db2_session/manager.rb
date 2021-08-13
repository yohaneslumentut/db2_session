# frozen_string_literal: true

module Db2Session
  module Manager
    mattr_reader :sessions
    @@sessions = Concurrent::Map.new

    mattr_reader :hmac_secret
    @@hmac_secret = SecureRandom.hex(64)

    def db2_config
      Db2Query::Base.config
    end

    def authenticate!
      Thread.current[:connection] = current_connection
      yield
    rescue Exception => e
      render json: { message: e.message }, status: :unauthorized
    ensure
      Thread.current[:connection] = nil
    end

    def create_new_connection
      new_session_connection.tap do |connection|
        sessions.fetch_or_store(connection.object_id, connection)
      end
    end

    def flush_idling_connections!
      sessions.each_pair do |key, conn|
        sessions.delete_pair(key, conn) if idle_connection?(conn)
      end
    end

    private
      def payload(key)
        { data: { session_key: key } }
      end

      def token(key)
        JWT.encode payload(key), hmac_secret, "HS256"
      end

      def request_token
        request.authorization.split(" ").last
      end

      def decoded_token
        JWT.decode request_token, hmac_secret, true, { algorithm: "HS256" }
      end

      def request_key
        decoded_token.first["data"].transform_keys(&:to_sym)[:session_key]
      end

      def idle_connection?(conn)
        current_time - conn.trx_time > 30 * 60
      end

      def new_session_connection
        Db2Session::Connection.new(db2_config, params[:userid], params[:password])
      end

      def current_time
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end

      def current_connection
        sessions.fetch(request_key).tap do |conn|
          conn.trx_time = current_time
        end
      end
  end
end
