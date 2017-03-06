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
    @ondemand = false;
  end

  def putTemplates templates
    @templates = templates.select do |template|
      @templateNames.include? template.name
    end
  end

  def manifest
    data = yaml(properties, "    ")
    STDERR.puts ".........."+ data.to_s
    data;
  end

  def properties
    result = {}
    STDERR.puts "on demand is:: "+@ondemand.to_s
    @templates.each do |template|
      obj = template.manifest.toManifest(@name, @skip_default, @ondemand);
      result.deep_merge! obj;
    end
    result.deep_merge! pairToHash(@manifest_config)
    # STDERR.puts "result properties is:: "+result.to_s
  end

  def property_blueprints
    result =[]
    @templates.each do |template|
      result.push *template.property_blueprints;
    end

    hardcoded = {}
    !@manifest_config.nil? && @manifest_config.each do |key, value|
      hardcoded[toJobPropName key] = value
    end
    result.select do |property_blueprint|
      hardcoded[property_blueprint["name"]].nil?
    end
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