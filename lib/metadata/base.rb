class Base

  def []=(k, v)
    self.send(k,v)
  end

  def [](k)
    self.send(k)
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
end