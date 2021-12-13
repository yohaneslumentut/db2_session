# Db2Session

[![Gem Version](https://badge.fury.io/rb/db2_session.svg)](https://badge.fury.io/rb/db2_session)

A Rails 5 & Rails 6 plugin for managing queries by sessions of authenticated db2 (i-series) multi-users on a remote db2 server.

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'db2_session'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install db2_session
```
## Usage
This plugin highly depends on [Db2Query](https://github.com/yohaneslumentut/db2_query). Where **Db2Query** is responsible to manage database queries and **Db2Session** is only responsible to manage user sessions in the controllers of each query.

Note: Please do the Db2Query [**Initialization**](https://github.com/yohaneslumentut/db2_query#2-initialization) steps before move to the next section.

Rules:
> 1. **Queries** have to extend ApplicationQuery, an abstract query, which inherit all attributes and methods required from Db2Session::ApplicationQuery
> 2. **Controllers** have to extend Db2Controller, an abstract controller, which inherit all attributes and methods required from Db2Session::ApplicationController

### Load Configuration
Modified `db2query` initializer and load the configuration at `app_root/config/initializers/db2query.rb`
```ruby
# app_root/config/initializers/db2query.rb

require "db2_session"

Db2Query::Base.initiation do |base|
  base.set_field_types
end

Db2Session::ApplicationQuery.establish_connection
```


### Mount Engine Authentication Path
To be able to use the **authentication** path, mount the engine at your application `config/routes.rb`
```ruby
Rails.application.routes.draw do
  mount Db2Session::Engine => "/db2_session"
  ...
end
```
The `db2_session/login` and `db2_session/logout` path is now available at `rails routes`

```bash
$ rails routes
     Prefix Verb URI Pattern           Controller#Action
db2_session      /db2_session          Db2Session::Engine
...
Routes for Db2Session::Engine:
      login POST /login(.:format)      db2_session/sessions#new
     logout GET  /logout(.:format)     db2_session/sessions#delete
...
```

### Query By User Session
**Db2Query** use only one user which is hardcoded at `config/db2query.yml`. Here, at Db2Session query, multi-user can make requests and queries by using their own db2 credential that is securely attached at connection client instance. The plugin will assign the connection to the related user on each request based on an attached token that was created during the `login` process.

Create an abstract query, here we use `ApplicationQuery` that extend `Db2Session::ApplicationQuery`. All of your query class have to extend this class. 

```ruby
# app/queries/application_query.rb
class ApplicationQuery < Db2Session::ApplicationQuery
  def self.inherited(subclass)
    subclass.define_query_definitions
  end
end
```

Then create a `Db2ConnectionQuery` that inherit from `ApplicationQUery`

```bash
$ rails g query db2_connection --defines status
```
```ruby
# app/queries/db2_connection_query.rb
class Db2ConnectionQuery < ApplicationQuery
  def status_sql
    "SELECT 1 AS CONNECTED FROM SYSIBM.SYSDUMMY1"
  end
end
```
Update the definitions:
```ruby
# app/queries/definitions/db2_connection_query_definitions.rb
module Definitions
  class Db2ConnectionQueryDefinitions < Db2Query::Definitions
    def describe
      query_definition :status do |c|
        c.connected :boolean
      end
    end
  end
end

```

### Session Controller

Next, create a `Db2Session::Controller` as a base controller and `Db2ConnectionController` that extend the base controller where we can render `Db2ConnectionQuery.status`.

```ruby
# app/controllers/db2_session/controller.rb
module Db2Session
  class Controller < Db2Session::ApplicationController
    private
      def request_token
        return nil unless request.authorization
        request.authorization.split(" ").last
      end
  end
end

# app/controllers/db2_connection_controller.rb
class Db2ConnectionController < Db2Session::Controller
  def index
    status = Db2ConnectionQuery.status
    render json: {
      data: {
        user: Db2ConnectionQuery.connection.userid,
        trx_time: Db2ConnectionQuery.connection.trx_time,
        connected: status.connected
      }
    }
  end
end
```
Add the route at `config/routes`:
```ruby
Rails.application.routes.draw do
  mount Db2Session::Engine => "/db2_session"
  get "/db2_connection", to: "db2_connection#index"
end

```

Then check whether the `db2_connection_path` already listed at application routes. 
```bash
$ rails routes
         Prefix Verb URI Pattern               Controller#Action
    db2_session      /db2_session              Db2Session::Engine
 db2_connection GET  /db2_connection(.:format) db2_connection#index

Routes for Db2Session::Engine:
          login POST /login(.:format)          db2_session/sessions#new
         logout GET  /logout(.:format)         db2_session/sessions#delete
```

### REST

First, run your development server
```bash
$ rails s
```
Post a login request with Db2 `userid` and `password` data to get a token.

```bash
$ curl -XPOST -i -H "Content-Type: application/json" -d '{ "userid": "YOHANES", "password": "XXXXXX" }' http://localhost:3000/db2_session/login
```
The installation success if you see response as follow:
```bash
HTTP/1.1 200 OK 
X-Frame-Options: SAMEORIGIN
X-Xss-Protection: 1; mode=block
X-Content-Type-Options: nosniff
X-Download-Options: noopen
X-Permitted-Cross-Domain-Policies: none
Referrer-Policy: strict-origin-when-cross-origin
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJkYXRhIjp7InNlc3Npb25fa2V5Ijo0NzM0Mzg2MTIzNTE2MH19.KW5NZo43WT47QiKrXvVyRd2kovY1Y53fSabU2BIx5nc
Content-Type: application/json; charset=utf-8
Vary: Accept
Etag: W/"883b4f34583e448cb88bf7c2146dc445"
Cache-Control: max-age=0, private, must-revalidate
X-Request-Id: 9411f926-404d-4b6c-9b4e-349b02560cfa
X-Runtime: 0.259895
Server: WEBrick/1.4.2 (Ruby/2.6.4/2019-08-28)
Date: Fri, 13 Aug 2021 04:58:15 GMT
Content-Length: 35
Connection: Keep-Alive

{"message":"YOHANES are logged in."}
```
Copy the Authorization Bearer token, and use it to check connection status.
```bash
$ curl -XGET -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJkYXRhIjp7InNlc3Npb25fa2V5Ijo0NzM0Mzg2MTIzNTE2MH19.KW5NZo43WT47QiKrXvVyRd2kovY1Y53fSabU2BIx5nc" -H "Content-Type: application/json" http://localhost:3000/db2_connection
```
Note: Replace the token with your own token that generated during login process.

Then the response will be as follow:
```ruby
 {"data":{"user":"YOHANES","trx_time":14556.481167844,"connected":true}}
```

Now the token can be use on each **REST** request to your application.


### GraphQL

Install [graphql-ruby](https://github.com/rmosolgo/graphql-ruby)

Initialize `graphql-ruby`
```bash
$ rails generate graphql:install
```

Make a change at `app/controller/graphql_controller.rb` by replacing `ApplicationController` with `Db2Session::Controller`
```ruby
# app/controller/graphql_controller.rb
class GraphqlController < Db2Session::Controller
...
end

```

### GraphiQL

Install [graphiql-rails](https://github.com/rmosolgo/graphiql-rails) gem.

Create an `app/assets/config/manifest.js`:
```bash
$ mkdir -p app/assets/config && touch app/assets/config/manifest.js
```
For API only, let the file empty and for full Rails application:
```ruby
# app/assets/config/manifest.js
//= link_tree ../images
//= link_directory ../stylesheets .css
```

And create a config/initializers/assets.rb with:
```ruby
# config/initializers/assets.rb
if Rails.env.development?
  Rails.application.config.assets.precompile += %w[graphiql/rails/application.js graphiql/rails/application.css]
end
```
Then create `app/controllers/graphiql/rails/editors_controller.rb` to overide the `graphiql-rails` engine's editors controller
```ruby
# app/controllers/graphiql/rails/editors_controller.rb
module GraphiQL
  module Rails
    class EditorsController < ActionController::Base
      attr_reader :auth_token

      include Db2Session::Manager

      before_action :authenticate
      def show
        GraphiQL::Rails.config.headers["Authorization"] = -> (_) { "Bearer #{auth_token}" }
      end

      helper_method :graphql_endpoint_path
      def graphql_endpoint_path
        params[:graphql_path] || raise(%|You must include `graphql_path: "/my/endpoint"` when mounting GraphiQL::Rails::Engine|)
      end

      protected
        def authenticate
          unless auth_token
            authenticate_or_request_with_http_basic do |username, password|
              params[:userid] = username
              params[:password] = password
              connection = fetch_or_create_connection
              connection.trx_time = current_time
              @auth_token = token(connection.object_id)
            rescue
              false
            end
          end
        end

        def connections
          sessions.keys.map do |key|
            conn = sessions.fetch(key)
            conn.userid == params[:userid] ? conn : nil
          end
        end

        def fetch_or_create_connection
          connections.first || create_new_connection
        end
    end
  end
end
```
Add the path at `config/routes.rb`
```ruby
# config/routes.rb
Rails.application.routes.draw do
  ...
  post "/graphql", to: "graphql#execute"

  if Rails.env.development?
    get "/graphiql" => "graphiql/rails/editors#show", graphql_path: "/graphql"
  end
  ...
end
```
Start development server
```bash
$ rails s
```

Go to `http://localhost:3000/grahpiql` and at the first visit, you will be asked `db2 credential` to get a token that will be used by `grahpiql-rails` on each request to `http://localhost:3000/grahpql`.

Example of Connection status query:

Create connection status type
```ruby
# app/graphql/types/connection_status.rb
module Types
  class ConnectionStatus < Types::BaseObject
    field :user, String, null: true
    field :trx_time, Integer, null: true
    field :connected, Boolean, null: true
  end
end
```

Register at query type:
```ruby
# app/graphql/types/query_type.rb
module Types
  class QueryType < Types::BaseObject
    ...
    field :connection_status, resolver: Queries::ConnectionStatusQuery
    ...
  end
end
```

Create a query resolver:
```ruby
# app/graphql/queries/connection_status_query.rb
module Queries
  class ConnectionStatusQuery < GraphQL::Schema::Resolver
    type Types::ConnectionStatus, null: false

    def resolve
      {
        user: connection.userid,
        trx_time: connection.trx_time,
        connected: status.connected
      }
    end

    protected
      def status
        Db2ConnectionQuery.status
      end

      def connection
        Db2ConnectionQuery.connection
      end
  end
end
```
Go to `http://localhost:3000/grahpiql` and make a query request to `GraphQL` at `GraphiQL` editor:

```text
query {
  connectionStatus {
    user
    trxTime
    connected
  }
}
```
and you will get response:
```text
{
  "data": {
    "connectionStatus": {
      "user": "YOUR USER ID",
      "trxTime": ..........,
      "connected": true
    }
  }
}
```
Done.

### How to test a Query

Create `Db2Session::IntegrationTest` class that extend `ActionDispatch::IntegrationTest`:
```ruby
# app/test/test_helper.rb

module Db2Session
  class  IntegrationTest < ActionDispatch::IntegrationTest
    attr_reader :request_token

    include Db2Session::Manager

    setup do
      # get the credentials from environment variable
      user_1 = ENV["USER1_ID"]   
      user_1_password = ENV["USER1_PASSWORD"]

      db2_session = Db2Session::Engine.routes.url_helpers
      post db2_session.login_path, params: { userid: user_1, password: user_1_password }, as: :json
      @request_token = @response["Authorization"].split(" ").last

      Thread.current[:connection] = current_connection
    end
  end
end
```

Then extend it at your query test:
```ruby
# app/test/queries/db2_connection_query_test.rb

require "test_helper"

class Db2ConnectionQueryTest < Db2Session::IntegrationTest
  test "connection status" do
    status = Db2ConnectionQuery.status
    assert status.connected
  end
end
```

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
