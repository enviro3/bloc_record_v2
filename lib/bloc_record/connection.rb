require 'sqlite3'
require 'pg'

 module Connection
   def connection
     if BlocRecord.database_database == :sqlite3
       @connection ||= SQLite3::Database.new(BlocRecord.database_filename)
     end

     if BlocRecord.database_database == :pg
       @connection ||= Postgres::Database.new(BlocRecord.database_filename)
     end
   end
 end
