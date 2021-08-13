# frozen_string_literal: true

class ConnectionQuery < ApplicationQuery
  def status_sql
    "SELECT 1 AS CONNECTED FROM SYSIBM.SYSDUMMY1"
  end
end
