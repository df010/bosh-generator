require_relative "base"
#ondemand broker
class Broker < Base
  attr_reader :manifest, :property_blueprints

  def initialize config, job_types,releaseVersion
    br =byName(config["ondemand_job_types"],"broker")
    @manifest=br["manifest"]
    multipleNetwork = (true == br["multiple_network"])
    setProp @manifest, "service_deployment.stemcell", {"os"=>"ubuntu-trusty","version"=>config["stemcell_version"]}, false
    setProp @manifest, "service_catalog.bindable", true, false
    setProp @manifest, "service_catalog.plan_updatable", true, false

    @manifest["service_deployment"]["releases"].each do |rel|
      rel["version"]= releaseVersion.to_s
    end

    @property_blueprints = []
    @manifest["service_catalog"]["plans"].each do |plan|
      props = {}
      plan["instance_groups"].each do |instance_group|
        setProp instance_group, "vm_type", "(( "+instance_group["name"]+"_vm_type.value ))", false
        setProp instance_group, "vm_extensions", [], false
        setProp instance_group, "networks", ["(( $self.service_network ))"], false
        setProp instance_group, "azs", "(( service_az_multi_select.value ))", false
        aProp = byName(job_types,instance_group["name"]).properties;
        !aProp.nil?  && (props.deep_merge! aProp)
        # prps.nil? && prps = {}
        # !instance_group["properties"].nil?  && (prps.deep_merge! instance_group["properties"]);
        # instance_group["properties"]= prps;

        @property_blueprints.push( {"name" => instance_group["name"]+"_vm_type" ,"configurable"=>true, "type" => "vm_type_dropdown", "optional" => false} )
      end
      if(multipleNetwork)
        props["metadata_config"]={"network"=>"(( network_config.value ))"}
      end
      plan["properties"].nil? && plan["properties"]={}
      plan["properties"] = props.deep_merge! plan["properties"]
      #STDERR.puts "plan properties are:: "+plan["properties"].to_s
    end

    @property_blueprints.push( {"name" => "service_az_multi_select" ,"configurable"=>true, "type" => "service_network_az_multi_select", "optional" => false} )
    @property_blueprints.push( {"name" => "broker_basic_auth" , "type" => "simple_credentials"} )
    if multipleNetwork
        @property_blueprints.push( {"name" => "network_config" , "type" => "string","configurable"=>true, "optional" => false} )
    end
    @manifest["username"] = "(( broker_basic_auth.identity ))"
    @manifest["password"] = "(( broker_basic_auth.password ))"
    @brokeryml = {}
    @brokeryml["input_mappings"] =byName(config["ondemand_job_types"],"broker")["input_mappings"]
    @brokeryml["binding_credentials"]=byName(config["ondemand_job_types"],"broker")["binding_credentials"]
    @brokeryml["instance_groups"]=job_types.map{|job|
      ig={};
      ig["name"]=job["name"];
      ig["templates"]=job.templates.map {|template|template["name"]};
      ig
    }

    shared_input_mappings.each {|map|
      @property_blueprints.push( {"name" => toJobPropName(map["key"] ), "type" => "string","configurable"=>true, "optional" => false} )
    }
    self.property_inputs #only generate property inputs for broker inputs, not the ones generated by other jobs

    job_types.each{|job| @property_blueprints.push *filter(job.property_blueprints ,job.name)}

    @manifest["service_catalog"]["plans"].each do |plan|
      plan["properties"] = update_props (plan["properties"])
    end
  end


  def manifest
    yaml @manifest, "    "
  end

  def config
    @brokeryml.to_yaml
  end

  def property_blueprints format=false
    transform( @property_blueprints, format, "  ")
  end

  def property_inputs format=false
    transform( _property_inputs(), format, "  ")
  end

  def ignore_map prefix, transform_key=false
    result = {}
    if(!prefix.nil?)
      if !(prefix.end_with? "_")
        prefix =prefix+"_"
      end
    else
      prefix =""
    end
    #STDERR.puts autogen_input_mappings.to_s
    autogen_input_mappings.each {|item|
      result[prefix+item["key"]]= item["valuemap"]
    }
    shared_input_mappings.each {|item|
      result[prefix+item["key"]]= "(( "+toJobPropName(item["key"])+".value ))"
    }
    if transform_key
      result = tranforminputkeys result;
    end
    result
  end

  private
  def update_props props
    map = ignore_map nil,false
    # STDERR.puts "ignore map is::  "+map.to_s
    map.each {|key, value|
      # STDERR.puts "ignore map is::  "+key.to_s+" and "+value.to_s
      updateEle props, key, value
    }
    # removeEmpty props
    # STDERR.puts "props after update is "+props.to_s
    props
  end

  def updateEle props, key, value
    paths = key.split "."
    val = props
    for i in 0..(paths.length-1)

      if i == (paths.length-1)
        val[paths[i]] =value
      elsif val[paths[i]].nil?
        val[paths[i]] = {}
      end
      val =  val[paths[i]]
    end
    return props;
  end


  # def removeEmpty props
  #   props.
  #
  # end
  def filter property_blueprints, jobName
    imap = ignore_map jobName,true
    #STDERR.puts "ignore map is:: "+imap.to_s
    property_blueprints.select {|propblue|
      imap[propblue["name"]].nil?
    }
  end

  def tranforminputkeys autogens
    result ={}
    autogens.each {|key, value|
      result[self.toJobPropName(key)] = value
    }
    result
  end


  def shared_input_mappings
    if !@brokeryml["input_mappings"].nil? 
      @brokeryml["input_mappings"].select {|map|
      map["shared"]
      } 
    else
        []
    end 
  end

  def autogen_input_mappings
    if !@brokeryml["input_mappings"].nil? 
        @brokeryml["input_mappings"].select {|map|
      !(map["valuemap"] =~ /^ *[0-9]*:auto *$/).nil?
      }
    else
        []
    end

  end

  def transform data, format=false, prefix="  "
    if !format
      return  data
    end
    yaml(data, prefix)
  end

  def _property_inputs
    if @property_inputs.nil?
      @property_inputs=(@property_blueprints.select{|prop| prop["configurable"] == true} ).map {|prop|
        {"reference"=> ".broker."+prop["name"], "label"=> prop["name"], "description"=> prop["name"]}
      }
    end
    @property_inputs
  end
end
