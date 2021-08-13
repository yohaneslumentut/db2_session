Rails.application.routes.draw do
  mount Db2Session::Engine => "/db2_session"
  get "/connection", to: "connection#index"
end
