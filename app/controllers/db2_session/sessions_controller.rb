# frozen_string_literal: true

module Db2Session
  class SessionsController < ApplicationController
    skip_around_action :authenticate!, only: [:new]

    def new
      connection = create_new_connection
      response.set_header("Authorization", "Bearer #{token(connection.object_id)}")
      render json: { message: "#{params[:userid]} are logged in." }
    rescue Db2Query::ConnectionError => e
      render json: { message: e.message }, status: :unauthorized
    end

    def delete
      request_key.tap do |key|
        connection = sessions.fetch(key)
        connection.disconnect!
        sessions.delete_pair(key, connection)
      end
      render json: { message: "You are logged out." }, status: :ok
    end
  end
end
