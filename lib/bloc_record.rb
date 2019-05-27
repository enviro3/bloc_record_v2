module BlocRecord
  def self.connect_to(filename)
    @database_filename = filename
    #logic which one will use, code here. could use global variable to store data type using, can use that variable in the connection
  end

  def self.database_filename
    @database_filename
  end
end
