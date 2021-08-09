# frozen_string_literal: true

module Db2Session
  class ApplicationController < ActionController::API
    include Db2Session::Manager
    around_action :authenticate!
  end
end
