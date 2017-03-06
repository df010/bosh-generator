require_relative 'base'
class Template < Base
  attr_reader :name, :label, :description, :manifest, :property_blueprints, :property_inputs

  def initialize specFile
    spec = YAML.load_file specFile

    @name = spec["name"];
    @description =replaceNewLine(if spec["description"].nil? then spec["name"] else spec["description"] end)
    @manifest = Manifest.new
    @property_blueprints = []
    @property_inputs = []

    !spec['properties'].nil? &&  spec['properties'].each do |key, value|
      @manifest.addProperty key, value["default"]
      addPropertyBlueprint key, value["default"]
      addPropInput key, value["description"]
    end
    if(@name== "broker-registrar")
      @property_blueprints.push( {"name" => "broker_credentials" ,"configurable"=>false, "optional"=>true, "type" => "simple_credentials", "default" => { "identity"=>"broker" }} )
    end
  end

  def addPropertyBlueprint (key, defaultValue)
    if(isEmbededPropValue key)
      return
    end
    if(!defaultValue.nil?  && defaultValue.is_a?(Array) )
      defaultValue =nil
    end
    prp = {"name" => toJobPropName(key) ,  "configurable"=>true, "optional"=>false,  "type" => toType(defaultValue) }
    if !defaultValue.nil?
      prp["default"]=defaultValue;
    end
    @property_blueprints.push( prp)
  end

  def addPropInput(key, desc)
    if isEmbededPropValue (key)
      return
    end
    if desc.nil? || desc.gsub(/ */,"") == ""
      desc = toJobPropName(key);
    end
    @property_inputs.push( {"description" => replaceNewLine(desc) , "label" => toJobPropName(key) ,"reference" => toJobPropName(key) } )

  end

    def toType(defaultValue)
      if(defaultValue.nil?)
        return "string"
      end
      if( is_number? defaultValue )
        return "number"
      end
      if( is_boolean? defaultValue)
        return "boolean"
      end
      if( is_array? defaultValue )
        return "string_list"
      end

      return "string"

    end

  def is_number? value
    !!(value =~ /\A[-+]?[0-9]+\z/)
  end

  def is_boolean? value
    return value.to_s == "true" || value.to_s == "false"
  end

  def is_array? value
    return value.is_a? Array
  end

  def replaceNewLine(str)
    if str.nil?
      return str;
    end
    return str.split("\n").join;
  end


  def isEmbededPropValue(key)
    return ["cf.admin_username","cf.admin_password","cf.system_domain","broker.username","broker.password"].include?(key)
  end

end