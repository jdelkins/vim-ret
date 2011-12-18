if Ret::platform == :Windows
  require 'ret/afile/win32'
else
  require 'ret/afile/unix'
end

module Ret
  class Afile
    attr_reader :basedir
    attr_reader :relpath
    
    class Type
      Reg = '-'
      Dir = 'd'
      CharDev = 'c'
      BlockDev = 'b'
      Fifo = 'p'
      Socket = 's'
      Symlink = 'l'
      Other = '?'
    end
    
    attr_reader :name

    def initialize(basedir, relpath)
      @basedir = basedir
      @relpath = relpath
      subinit()
    end

    def basename()
      File.basename(@relpath)
    end

    def pathname()
      case Ret.platform
      when :Unix    then return File.join(@basedir, @relpath)
      when :Windows then return "#{@basedir}\\#{@relpath}"
      end
    end

    def rebase(newbasedir, newrelpath)
      @basedir = newbasedir
      @relpath = newrelpath
    end

    def typecode
      case @lstat.ftype
      when "file"
        Type::Reg
      when "directory"
        Type::Dir
      when "link"
        Type::Symlink
      when "characterSpecial"
        Type::CharDev
      when "blockSpecial"
        Type::BlockDev
      when "fifo"
        Type::Fifo
      when "socket"
        Type::Socket
      else
        Type::Other
      end
    end
    
  end
end
