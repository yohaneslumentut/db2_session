class ConnectionController < ApplicationController
  def index
    status = ConnectionQuery.status
    render json: {
      data: {
        user: ConnectionQuery.connection.userid,
        trx_time: ConnectionQuery.connection.trx_time,
        connected: status.connected
      }
    }
  end
end
