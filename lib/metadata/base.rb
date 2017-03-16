class Base


  def []=(k, v)
    self.send(k,v)
  end

  def [](k)
    begin
      self.send(k)
    rescue NoMethodError
      STDERR.puts " try to find "+k.to_s+", but failed"
      @baseconfig[k]
    end
  end

  def get_from_arr(k, nameValue, eleKey, defaultValue=nil)
    STDERR.puts "try to get " + k.to_s + "   " + nameValue.to_s + "  " + eleKey.to_s + " " + defaultValue.to_s
    values = self[k]
    if values.nil?
      STDERR.puts "k is empty"
      return defaultValue
    end
    STDERR.puts values.to_s
    values.each {|item|
      if item["name"] == nameValue
        STDERR.puts "found " + item[eleKey].to_s
        return item[eleKey]
      end
    }
    STDERR.puts "nothing found "
    return defaultValue
  end


  def get(defaultValue,*k)
    # STDERR.puts "try to get " + k.to_s + "   " + nameValue.to_s + "  " + eleKey.to_s + " " + defaultValue.to_s
    var = nil;
    k.each {|item|
      if var.nil?
        var =self[item];
      else
        var = var[item]
      end
      if var == nil
        return defaultValue
      end
    }
    return var;
  end

  def toJobPropName (key)
    key.gsub /\./, "_"
  end

  def setProp (obj, key , value, override=true)
    data = obj;
    ks=key.split(".");
    size = ks.length
    ks.each_with_index do |k,i|
      if (i < size-1)
        if data[k].nil?
          data[k]={}
        end
        data=data[k]
      elsif override || data[k].nil?
        data[k]=value
      end
    end
  end

  def byName arr, name
    arr.each do |j|
      if( j.is_a? Hash)
        if j["name"] == name
          return j
        end
      else
        if j.name == name
          return j
        end
      end
    end
    return nil
  end

  def yaml data, prefix="  "
    if data.nil?
      return "";
    end
    if data.is_a? Array
      tmp={};
      tmp["TMP_B_NAME"]=data
      (yaml(tmp, prefix).split("\n").select {|str| str != prefix+"TMP_B_NAME:"}).join "\n"
    else
      data.to_yaml.gsub(/^(.*)/, prefix+"\\1").gsub("---", "");
    end
  end

  def hashToPair hash, prefix=""
    if hash.nil?
      {}
    else
      result = {}
      hash.each do |key, value|
        if(value.is_a? Hash)
          result.deep_merge! hashToPair value, prefix+key.to_s+"."
        else
          result[prefix+key.to_s]=value
        end
      end
      result
    end
  end
end