require 'ret/afile'

module Ret
  class Fileset
    attr_reader :afiles
    
    def initialize(arg)
      def from_dir(dir)
        @afiles = dir.map do |f|
          #Afile.new(File.join(dir.path, f))
          Afile.new(dir.path + "\\" + f)
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
    
    def list
      # determine column widths and pass to listing
      if Ret.platform == :Windows
        format = column_format_win32
      else
        format = column_format_unix
      end
      @afiles.map do |af|
        af.listing format
      end
    end
    
    def clone
      other = super.clone
      other.set_afiles @afiles.clone
    end
    
    protected
    
    def column_format_win32
      [
        "%s",
        "%-" + (@afiles.max { |a,f| a.owner.length <=> f.owner.length }).owner.length.to_s + "s",
        "%" + (@afiles.max { |a,f| a.size.to_s().length <=> f.size.to_s().length }).size.to_s().length.to_s + "d",
        "%s",
        "%s"
      ]
    end
    
    def column_format_unix
      []
    end
    
  end
end