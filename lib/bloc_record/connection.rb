require 'sqlite3'

 module Connection
   def connection
     @connection ||= SQLite3::Database.new(BlocRecord.database_filename) #connect to sqlite or postgres...
   end
 end
