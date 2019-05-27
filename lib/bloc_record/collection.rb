module BlocRecord
  class Collection < Array

    def update_all(updates)
      ids = self.map(&:id)

      self.any? ? self.first.class.update(ids, updates) : false
    end

    def to_collection(arr)
      c = Collection.new
      c.push(*arr)
      return c
    end

    def take(num=1)
      return self.to_collection(self[0...num])
    end

    def where(attributes=nil)
      if (attributes == nil)
        return self
      end
      arr = self.select do |bloc_record_element|
        return attributes.all? do |attribute_key, attribute_value|
          if (!bloc_record_element.instance_variables.include? attribute_key)
            return false
          end
          return bloc_record_element.instance_variable_get(attribute_key) == attribute_value
        end
      end
      return self.to_collection(arr)
    end

    def not(attributes)
      arr = self.select do |bloc_record_element|
        return attributes.all? do |attribute_key, attribute_value|
          if (!bloc_record_element.instance_variables.include? attribute_key)
            return true
          end
          return bloc_record_element.instance_variable_get(attribute_key) != attribute_value
        end
      end
      return self.to_collection(arr)
    end
end
