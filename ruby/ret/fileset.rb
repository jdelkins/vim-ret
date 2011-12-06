require 'ret/afile'

module Ret
  class Fileset
    attr_reader :afiles
    
    def self.new_from_directory(dir)
      me = Fileset.new
      afiles = Dir.new(dir).map do |f|
        Afile.new(File.join(dir, f))
      end
      me.set_afiles afiles
      return me
    end
    
    def clone
      other = super.clone
      other.set_afiles @afiles.clone
    end
    
    #protected
    
    def set_afiles(afiles)
      @afiles = afiles
    end
    
  end
end