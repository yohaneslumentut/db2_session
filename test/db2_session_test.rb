# frozen_string_literal: true

require "test_helper"

class Db2SessionTest < ActionDispatch::IntegrationTest
  test "it has a version number" do
    assert Db2Session::VERSION
  end

  test "authentication works" do
    user_1 = ENV["USER1_ID"]
    user_1_password = ENV["USER1_PASSWORD"]

    user_2 = ENV["USER2_ID"]
    user_2_password = ENV["USER2_PASSWORD"]

    Thread.new {
      post auth.login_path, params: { userid: user_1, password: user_1_password }, as: :json
      token = @response["Authorization"].split(" ").last
      get auth.logout_path, headers: { "Authorization": "Bearer #{token}" }
      assert true
    }.join

    Thread.new {
      post auth.login_path, params: { userid: user_2, password: user_2_password }, as: :json
      token = @response["Authorization"].split(" ").last
      get auth.logout_path, headers: { "Authorization": "Bearer #{token}" }
      assert true
    }.join

    Thread.new {
      post auth.login_path, params: {userid: user_1, password: user_1_password }, as: :json
      token = @response["Authorization"].split(" ").last
      get auth.logout_path, headers: { "Authorization": "Bearer #{token}" }
      assert true
    }.join
  end
end
