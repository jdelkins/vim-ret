require 'ret/afile'

module Ret
  class Fileset
    attr_reader :afiles
    
    def initialize(arg)
      def from_dir(dir)
        @afiles = dir.map do |f|
          Afile.new(File.join(dir.path, f))
        end
      end
      
      if arg.is_a? String
        from_dir(Dir.new(arg))
      elsif arg.is_a? Dir
        from_dir(arg)
      else
        raise TypeError, "Ret::Fileset.new called with incompatible type"
      end
      
    end
    
    def clone
      other = super.clone
      other.set_afiles @afiles.clone
    end
  end
end