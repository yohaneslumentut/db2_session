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
      Thread.current[:connection] = sessions.fetch(request_key)
      yield
    rescue
      render json: { message: "Unauthorized access" }, status: :unauthorized
    ensure
      Thread.current[:connection] = nil
    end

    def create_new_connection
      connection = new_session_connection
      sessions.fetch_or_store(connection.object_id, connection)
      connection
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

      def clear_existing_connection
        sessions.each_pair do |key, conn|
          if conn.userid == params[:userid]
            sessions.delete_pair(key, conn)
          end
        end
      end

      def new_session_connection
        Db2Session::Connection.new(db2_config, params[:userid], params[:password])
      end
  end
end
