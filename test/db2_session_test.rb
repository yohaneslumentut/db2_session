# frozen_string_literal: true

require "test_helper"

class Db2SessionTest < ActionDispatch::IntegrationTest
  test "it has a version number" do
    assert Db2Session::VERSION
  end

  test "multi user authentication works" do
    user_1 = ENV["USER1_ID"]
    user_1_password = ENV["USER1_PASSWORD"]

    user_2 = ENV["USER2_ID"]
    user_2_password = ENV["USER2_PASSWORD"]

    db2_session = Db2Session::Engine.routes.url_helpers

    Thread.new {
      post db2_session.login_path, params: { userid: user_1, password: user_1_password }, as: :json
      token = @response["Authorization"].split(" ").last
      get db2_session.logout_path, headers: { "Authorization": "Bearer #{token}" }
      assert true
    }.join

    Thread.new {
      post db2_session.login_path, params: { userid: user_2, password: user_2_password }, as: :json
      token = @response["Authorization"].split(" ").last
      get db2_session.logout_path, headers: { "Authorization": "Bearer #{token}" }
      assert true
    }.join

    Thread.new {
      post db2_session.login_path, params: { userid: user_1, password: user_1_password }, as: :json
      token = @response["Authorization"].split(" ").last
      get db2_session.logout_path, headers: { "Authorization": "Bearer #{token}" }
      assert true
    }.join
  end

  test "db2 query works" do
    app = Dummy::Application.routes.url_helpers

    user_1 = ENV["USER1_ID"]
    user_1_password = ENV["USER1_PASSWORD"]

    post db2_session.login_path, params: { userid: user_1, password: user_1_password }, as: :json
    token = @response["Authorization"].split(" ").last
    get app.connection_path, headers: { "Authorization": "Bearer #{token}" }

    response = JSON.parse @response.body.gsub("=>", ":")
    data = response["data"]

    assert_equal user_1, data["user"]
    assert data["connected"]
  end
end
