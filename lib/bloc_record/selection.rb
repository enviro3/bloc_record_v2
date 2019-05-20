require 'sqlite3'

module Selection
  def method_missing(method_name, *arguments)
    method_name = method_name.to_s
    if method_name.start_with?("find_by_")
      column_they_hope_exists = method_name["find_by_".length..method_name.length]
      if self.class.columns.any? {|column| column === column_they_hope_exists}
        find_by(column_they_hope_exists, *arguments)
      else
        puts "Cannot do find_by on non-existant column #{column_they_hope_exists}"
      end
    else
      puts "The method you tried to use, #{method_name} does not exist -- try another"
    end

  end

  def find_in_batches(batch_size: 1000, start: 0, finish:)
    if finish != nil && start > finish
      return
    end
    limit = batch_size
    current_position = start
    while true
      if finish != nil
        distance_to_finish_line = [0, finish - current_position].max
        limit = [batch_size, distance_to_finish_line].min
      end
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        LIMIT #{limit} OFFSET #{current_position};
      SQL
      rows = rows_to_array(rows)
      yield rows
      current_position = current_position + rows.length
      if rows.length === 0
        return
      end
    end
  end

  def find_each(batch_size:, start:, finish:)
    find_in_batches(batch_size: batch_size, start: start, finish: finish) do |listings|
      listings.each {|listing| yield listing}
    end
  end



  def find(*ids)

    if ids.length == 1
      find_one(ids.first)
    elsif ids > 0
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        WHERE id IN (#{ids.join(",")});
      SQL

      rows_to_array( rows)

    else
      puts 'The ID you entered is invalid.'
      return -1
    end
  end

  def find_one(id)
    if id.is_a?(Integer) && id > 0
      row = connection.get_first_row <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        WHERE id = #{id};
      SQL

      init_object_from_row(row)
    else
      puts "ID is invalid"
      return -1
    end
  end

  def find_by(attribute, value)
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE #{attribute} = #{BlocRecord::Utility.sql_strings(value)};
    SQL

    rows_to_array(rows)
  end

  def take(num=1)
    if num > 1
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        ORDER BY random()
        LIMIT #{num};
      SQL

      rows_to_array(rows)
    else
      take_one
    end
  end

  def take_one
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY random()
      LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def first
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id ASC LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def last
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id DESC LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def all
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table};
    SQL

    rows_to_array(rows)
   end

   def where(*args)
     if args.count > 1
       expression = args.shift
       params = args
     else
       case args.first
       when String
         expression = args.first
       when Hash
         expression_hash = BlocRecord::Utility.convert_keys(args.first)
         expression = expression_hash.map {|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")
       end
     end

     sql = <<-SQL
       SELECT #{columns.join ","} FROM #{table}
       WHERE #{expression};
     SQL

     rows = connection.execute(sql, params)
     rows_to_array(rows)
   end

   def order(*args)
     orderedArray = []
     args.each {|arg|
       case arg
       when String
         orderedArray.push(arg)
       when Symbol
         orderedArray.push(arg.to_s)
       when Hash
         expression_hash = BlocRecord::Utility.convert_keys(arg)
         expression = expression_hash.map {
           |key, value| "#{key} #{value}"
         }.join(", ")
         orderedArray.push(expression)
       end
     }
     sql = <<-SQL
       SELECT #{columns.join ","} FROM #{table}
       WHERE #{orderedArray.join ", "};
     SQL

     rows = connection.execute(sql, params)
     rows_to_array(rows)
   end

   def join(*args)
     if args.count > 1
       joins = args.map { |arg| "INNER JOIN #{arg} ON #{arg}.#{table}_id = #{table}.id"}.join(" ")
       rows = connection.execute <<-SQL
         SELECT * FROM #{table} #{joins}
       SQL
     else
       case args.first
       when String
         rows = connection.execute <<-SQL
           SELECT * FROM #{table} #{BlocRecord::Utility.sql_strings(args.first)};
         SQL
       when Symbol
         rows = connection.execute <<-SQL
           SELECT * FROM #{table}
           INNER JOIN #{args.first} ON #{args.first}.#{table}_id = #{table}.id
         SQL
       when Hash

         expression = args.first.map {
           |key, value| "
            INNER JOIN #{key.to_s} ON #{key.to_s}.#{table}_id = #{table}.id
            INNER JOIN #{value.to_s} ON #{value.to_s}.#{key.to_s}_id = #{key.to_s}.id
          "
         }.join(" ")
         rows = connection.execute <<-SQL
           SELECT * FROM #{table}
           #{expression}
         SQL
       end
     end

     rows_to_array(rows)
   end


  private

  def init_object_from_row(row)
    if row
      data = Hash[columns.zip(row)]
      new(data)
    end
  end

  def rows_to_array(rows)
    collection = BlocRecord::Collection.new
    rows.each { |row| collection << new(Hash[columns.zip(row)]) }
    collection
  end
end
