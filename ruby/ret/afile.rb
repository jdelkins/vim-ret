if ENV['OS'] == 'Windows_NT'
  require 'ret/afile/win32'
else
  require 'ret/afile/unix'
end

module Ret
  class Afile
    
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

    def initialize(path)
      @name = File.basename(path)
      @dirname = File.dirname(path)
      @lstat = File.lstat(path)
      if File.symlink?(path)
        @target = File.readlink(path)
        @target_stat = File.stat(@target)
      end
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
