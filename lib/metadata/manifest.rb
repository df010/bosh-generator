require_relative 'base'
class Manifest < Base
  attr_reader :properties

  def initialize
    @properties = {}

  end

  def addProperty key, default
    @properties[key] = default;
  end

  def toManifest (jobName, skipDefault=false,ondemand=false)
    # {}.each_pair
    manifest = {}
    @properties.each do |key, value|
      if value.nil? || !skipDefault
        data = manifest;
        ks=key.split(".");
        size = ks.length
        ks.each_with_index do |k,i|
          if (i < size-1)
            if data[k].nil?
              data[k]={}
            end
            data=data[k]
          else
            data[k]=getPropValue(jobName,key,ondemand)
          end
        end
      end
    end
    manifest;
  end


  private
  def getPropValue(jobName,key,ondemand)
    case key
      when "cf.admin_username"
        return "(( ..cf.uaa.admin_credentials.identity ))"
      when "cf.admin_password"
        return "(( ..cf.uaa.admin_credentials.password ))"
      when "cf.system_domain"
        return "(( $runtime.system_domain ))"
      when "broker.username"
        if(jobName == "broker-deregistrar")
          return "(( .broker-registrar.broker_credentials.identity ))"
        end
        return "(( broker_credentials.identity ))"
      # return "user"
      when "broker.password"
        if(jobName == "broker-deregistrar")
          return "(( .broker-registrar.broker_credentials.password ))"
        end
        return "(( broker_credentials.password ))"
      # return "password"
      else
        if ondemand
          key = jobName+"."+key
        end
        #STDERR.puts " result map is:: " +"(( "+toJobPropName(key)+ ".value ))"
        return "(( "+toJobPropName(key)+ ".value ))";
    end
  end

end