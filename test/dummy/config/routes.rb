Rails.application.routes.draw do
  mount Db2Session::Engine, at: "/db2_session", :as => "auth"
end
