require_relative 'job'
require_relative 'form'
require_relative 'manifest'
require_relative 'base'
class Release < Base
  attr_reader :releaseFolder, :releaseName, :releaseFile, :releaseVersion, :job_types, :form_types, :config, :broker

  def initialize releaseFile
    datas= releaseFile.split "dev_releases"
    if datas.length ==1
      datas = releaseFile.split "releases"
    end
    @releaseFolder = datas[0];
    path = datas[1][1..-1];
    datas = path.split "/"
    @releaseName = datas[0];
    @releaseFile = datas[1];
    @releaseVersion = @releaseFile.gsub /#{@releaseName}-(.*)\.tgz/, "\\1";
    @config = YAML.load_file @releaseFolder+"/manifests/template.yml"
    @job_types = []
    @form_types =[]
    @config["job_types"].each do |job |
      @job_types.push Job.new job, @releaseName;
      @form_types.push Form.new job;
    end
    @templates = Dir.glob( @releaseFolder+"/jobs/**/spec").map do |specFile|
      Template.new specFile
    end
    @job_types.each do |job|
      job.putTemplates @templates
      byName(@form_types, job.name).templates =job.templates
    end
    if(!config["ondemand_job_types"].nil?)
      @job_types.each {|job| job.ondemand = true}
      @form_types.each {|form| form.ondemand = true}
      @broker = Broker.new @config,@job_types
      @form_types.each {|form| form.ignore_map = (@broker.ignore_map nil,true)}
    end
    # STDERR.puts "form types are:: "+form_types.to_s
  end

end