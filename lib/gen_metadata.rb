#!/usr/bin/env ruby
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'yaml'
require 'erb'
require 'fileutils'
require 'metadata/metadata'

class ::Hash
    def deep_merge(second)
        merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
        self.merge(second, &merger)
    end
    def deep_merge!(second)
        merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge!(v2, &merger) : v2 }
        self.merge!(second, &merger)
    end
end

class GenMetadata

    def initialize(items)#args from command line
        @erbFile = items[0];
        @metadata = Metadata.new items[1]
    end

    # Expose private binding() method.
    def get_binding
        binding()
    end

    def p(key, default=nil)
        result=@metadata[key];
        if(result.nil? && !default.nil?)
            return default
        end
        if result.nil?
            raise Exception.new("key: "+key +" is not defined")
        end
        return result
    end

    def p?(key)
        return !@metadata[key].nil?
    end

    #
    def o (preKey,nameValue)
        STDERR.puts "prekey is:: "+preKey.to_s
        @metadata[preKey].each do |item|
          if(item["name"] == nameValue)
              return item;
          end
      end
      return nil;
    end

    def job_exist?(jobName)
        @metadata["job_types"].each do |job_type|
            if(job_type["name"] == jobName)
                return true;
            end
        end
      return false;
    end

    def run()
        renderer = ERB.new(File.open(@erbFile, "rb").read);
        puts renderer.result(get_binding)
    end

    def ondemandjob()
        puts @metadata.broker.config
    end
end


if __FILE__ == $0
    gen= GenMetadata.new (ARGV)
  if "config" == ARGV[2]
    gen.ondemandjob
  else
      gen.run
  end


end



