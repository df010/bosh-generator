require_relative 'template'
require_relative 'base'
class Job < Base
  attr_reader :name, :label, :errand, :description, :release, :templates, :skip_default
  attr_accessor :ondemand

  def initialize job, releaseName
    @name = job['name'];
    @label = job['name'];
    @errand = job['errand'];
    @description = job['description'];
    @manifest_config = job['manifest']
    @release = releaseName;
    @templateNames = job["templates"];
    @skip_default = ("true" == job["skip_default"]);
    # @resource_definitions = job["resource_definitions"]
    # @instance_definition = job["instance_definition"]
    @baseconfig = job
    @ondemand = false;
  end

  def putTemplates templates
    @templates = templates.select do |template|
      @templateNames.include? template.name
    end
  end

  def manifest
    data = yaml(properties, "    ")
    #STDERR.puts ".........."+ data.to_s
    data;
  end

  def properties
    result = {}
    #STDERR.puts "on demand is:: "+@ondemand.to_s
    @templates.each do |template|
      obj = template.manifest.toManifest(@name, @skip_default, @ondemand);
      result.deep_merge! obj;
    end
    result.deep_merge! @manifest_config
    # #STDERR.puts "result properties is:: "+result.to_s
  end

  def property_blueprints
    result =[]
    @templates.each do |template|
      result.push *template.property_blueprints;
    end
    result = unique(result)

    hardcoded = {}
    credentials = {}
    !@manifest_config.nil? && hashToPair(@manifest_config, "").each do |key, value|
      STDERR.puts "hard coded key is:: "+key.to_s
      pushCredentialBlueprintsNames credentials, value
      hardcoded[toJobPropName key] = value
    end
    result = result.select do |property_blueprint|
      hardcoded[property_blueprint["name"]].nil?
    end
    credentials.each {|key, value|
      result.push( {"name" => key, "type" => "simple_credentials", "configurable" => false,  "default" => { "identity" => key.gsub(/(.*)_credentials/,"\\1") } })
    }
    if @ondemand
      return result.map {|prop|
        item = prop.clone;
        item["name"] =@name+"_"+item["name"]
        item
      }
    end
    result;
  end


  private

  def pushCredentialBlueprintsNames credentials, value
    if ! value.is_a? String
      return
    end
    cName = value.gsub(/^ *\(\( *([^\.]*)\.identity *\)\)/, "\\1")
    if( cName != value)
      credentials[cName]=cName
    end

    cName = value.gsub(/^ *\(\( *([^\.]*)\.password *\)\)/, "\\1")
    if( cName != value )
      credentials[cName]=cName
    end
  end
  def unique property_blueprints
    names = {}
    property_blueprints.select {|print|
      if (names[print["name"]].nil? )
        names[print["name"]]=print["name"];
        true
      else
        false
      end
    }
  end
  def pairToHash pair
    if pair.nil?
      {}
    else
      result = {}
      pair.each do |key, value|
        self.setProp result, key, value
      end
      result
    end
  end



end