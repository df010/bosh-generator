require_relative 'release'
require_relative 'base'
require_relative 'broker'
class Metadata < Base
  attr_accessor :releases, :name, :job_types, :ondemand_job_types, :form_types, :stemcell_version, :description, :icon_image, :product_version, :release


  def initialize releaseFile
    @release = Release.new releaseFile
    @config = @release.config
    @name = @config["name"];
    @releases=[{"name"=>@release.releaseName,"file"=>@release.releaseFile,"version"=>@release.releaseVersion}];
    @stemcell_version=if @config["stemcell_version"].nil? then "latest" else @config["stemcell_version"] end;
    @description=@config["description"];
    @icon_image=@config["icon_image"];
    @product_version=@config["product_version"];
    @baseconfig = @config

  end

    def ondemand?
      !@config["ondemand_job_types"].nil?
    end

  def job_types
    if !ondemand?
      @release.job_types
    else
      []
    end
  end

  def broker
    @release["broker"]
  end

  def ojob_types
    @release.job_types
  end

  def form_types
    @release.form_types.select do |form|
      STDERR.puts form.property_inputs.to_s
      !form.property_inputs.nil? && form.property_inputs.length >0
    end
  end

  private

  def transformManifest(parentNode)
    if !parentNode.nil?  && !parentNode["manifest"].nil?
      manifest={}
      parentNode["manifest"].each do |key, value|
        data=nil;
        ks=key.split(".");
        size = ks.length
        ks.each_with_index do |keyItem,i|
          if (i < size-1)
            if(data.nil?)
              data = manifest[keyItem];
              if(data.nil?)
                manifest[keyItem]={};
                data= manifest[keyItem];
              end
            else
              data = data[keyItem];
            end
          else
            if(data.nil?)
              data=manifest
            end
            data[keyItem]=value;
          end
        end
      end
      # parentNode["manifest"]=nil;
      parentNode["manifest"] =manifest;
    end
  end

end