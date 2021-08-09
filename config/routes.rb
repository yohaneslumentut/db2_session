# frozen_string_literal: true

Db2Session::Engine.routes.draw do
  post "/login", to: "sessions#new"
  get "/logout", to: "sessions#delete"
end
