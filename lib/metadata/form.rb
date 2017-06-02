require_relative 'base'
class Form < Base
  attr_reader :name, :label, :description, :templates, :manifest
  attr_writer :templates, :ondemand, :ignore_map
  def initialize job
    @name = job['name'];
    @description = if job['description'].nil? then job["name"] else job['description'] end;
    @label = job['name'];
    # @property_inputs = job['property_inputs'];
    @manifest_config = job['manifest']
    @ondemand = false;
  end

  def property_inputs
    initPropertyInputs
    # STDERR.puts "after init is:: "+@property_inputs.to_s
    @property_inputs
  end
  #
  # def filter_property_inputs filter
  #   [].map
  #   @property_inputs= self.property_inputs.select {|input|
  #     return filter[input["key"]].nil?
  #   }
  # end

  private
  def initPropertyInputs
    if @property_inputs.nil?
      hardcoded = {}
      !@manifest_config.nil?  && hashToPair(@manifest_config,"").each do |key, value|
        hardcoded[toJobPropName key] = value
      end
      @property_inputs = []
      @templates.each do |template|
        template.property_inputs.each do |item|
          if hardcoded[item["reference"]].nil?
            obj = item.clone
            if(! ignore obj["reference"])
              if !@ondemand
                if ! obj["reference"].start_with? "."+@name
                  obj["reference"]="."+@name+"."+obj["reference"];
                end
              else
                if ! obj["reference"].start_with? ".broker"
                  obj["reference"]=".broker."+@name+"_"+obj["reference"];
                end
              end
              @property_inputs.push obj
            end
          end
        end
      end
      @property_inputs = unique(@property_inputs)
    end
  end

  def unique property_inputs
    names = {}
    property_inputs.select {|print|
      if (names[print["reference"]].nil? )
        names[print["reference"]]=print["reference"];
        true
      else
        false
      end
    }
  end

    def ignore key
      # STDERR.puts "ignore map is:: "+@ignore_map.to_s
      # STDERR.puts "and key is:: "+key.to_s
      if @ignore_map.nil?
        return false
      end

      return !@ignore_map[key].nil?
    end

end