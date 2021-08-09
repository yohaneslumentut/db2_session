class ApplicationQuery < Db2Session::ApplicationQuery
  def self.inherited(subclass)
    subclass.define_query_definitions
  end
end
