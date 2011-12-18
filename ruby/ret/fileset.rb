require 'ret/afile'

module Ret

  class Fileset
    attr_reader :afiles
    attr_reader :basedir
    attr_reader :relpath
    attr_reader :mode
    attr_reader :skipdots
    
    def initialize(basedir, skipdots=false, relpath='.')
      @basedir = Fileset.normalize(Fileset.absolute?(basedir) ? basedir : Fileset.absolutize(basedir))
      @relpath = relpath
      @afiles = []
      @skipdots = skipdots

      fullpath = if @relpath == '.'
                   @basedir
                 else
                   Fileset.pathjoin(@basedir, @relpath)
                 end

      Dir.new(fullpath).each do |f|
        #Afile.new(File.join(dir.path, f))
        next if f == '.'
        next if @skipdots and f.start_with? '.' and f != '..'
        fp = if @relpath == '.'
               f
             else
               Fileset.pathjoin(@relpath, f)
             end
        af = Afile.new(@basedir, fp)
        next if @skipdots and af.hidden? and f != '..'
        @afiles << Afile.new(@basedir, fp)
      end
    end

    def rebase(newbasedir)
      if Fileset.absolute? newbasedir
        initialize(newbasedir, @skipdots, '.')
      else
        basedir2 = Fileset.normalize(Fileset.pathjoin(@basedir, newbasedir))
        initialize(basedir2, @skipdots, '.')
      end
      expand() if @mode == :expanded
    end

    # rolls up contents of all directories into this direcotry
    def expand()
      @mode = :expanded
      newfiles = []
      delete = []
      @afiles.each do |f|
        # handling for . and .. :
        # (1) we don't want to descend into those for sure (obviosuly, so we
        # skip them with next). 
        # (2) we don't want . and .. to show up at all except for the top
        # level, hence the relpath check.
        if ['.', '..'].include? f.basename
          delete << f unless ['.', '..'].include? f.relpath
          next
        end
        # skip any file with dots if so directed
        if @skipdots and f.hidden?
          delete << f unless ['.', '..'].include? f.relpath
          next
        end
        if f.directory?
          nfs = Fileset.new(@basedir, @skipdots, f.relpath)
          nfs.expand
          newfiles = newfiles + nfs.afiles
          delete << f unless nfs.afiles.empty?
        end
      end
      @afiles = @afiles + newfiles
      delete.each { |f| @afiles.delete f }
    end

    def rollup()
      @mode = :rolled
      initialize(@basedir, @skipdots, @relpath)
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
    
    # remove . and .. elements from an absolute or relative path
    def self.normalize(dir)
      fixed, _sep, rest = if absolute? dir
                            case Ret.platform
                            when :Unix    then [ '/', '', dir[1..-1] ]
                            when :Windows
                              if dir =~ /^\\\\|\/\//
                                [ '\\\\', '', dir[2..-1] ]
                              else
                                dir.partition /[\/\\]/
                              end
                            end
                          else
                            [ '', '', dir ]
                          end
      rest.split(@@pathsepre).each do |el|
        case el
        when ''       then next
        when '.'      then next
        when '..'     then fixed = File.dirname(fixed)
        else               fixed = pathjoin(fixed, el)
        end
      end
      return fixed
    end

    case Ret.platform
    when :Unix
      def self.absolute?(dir); dir.start_with? '/'; end
      def self.pathjoin(a, b); File.join(a, b); end
      def self.absolutize(d);  File.join(Dir.pwd, dir); end
      @@pathsepre = /\//
    when :Windows
      def self.absolute?(dir); dir =~ /^([A-Z]:(\\|\/)|\\\\)/; end
      def self.pathjoin(a, b); "#{a}\\#{b}"; end
      def self.absolutize(d);  pathjoin(Dir.pwd.gsub('/', '\\'), d); end
      @@pathsepre = /[\/\\]/
    end

    def column_format_win32
      [
        "%s",
        "%-#{(@afiles.map { |f| f.owner.length }).max.to_s}s",
        "%#{(@afiles.map { |f| f.size.to_s.length }).max.to_s}s",
        "%s",
        "%s"
      ]
    end
    
    def column_format_unix
      []
    end
    
  end
end
