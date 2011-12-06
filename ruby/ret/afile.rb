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
    
    class Perm
      None = '-'
      Read = 'r'
      Write = 'w'
      Execute = 'x'
      ExecSetUid = 's'
      SetUid = 'S'
      Sticky = 't'
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
    
    def listing
      x = "#{typecode}" +
        "#{rw(0400)}#{rw(0200)}#{x(0100)}" +
        "#{rw(0040)}#{rw(0020)}#{x(0010)}" +
        "#{rw(0004)}#{rw(0002)}#{x(0001)}  " +
        "#{user}  #{group}  #{@lstat.size}  " +
        "#{@name}"
      if @lstat.symlink?
        x += " -> #{@target}"
      end
      return x
    end
    
    private
    
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
    
    def rw(mask)
      @lstat.mode & mask ? Perm::Read : Perm::None
    end
    
    
    def x(mask)
      case [@lstat.mode & mask, @lstat.setuid?]
      when [true, true]
        Perm::ExecSetUid
      when [true, false]
        Perm::Execute
      when [false, true]
        Perm::SetUid
      else
        Perm::None
      end
    end
    
    def user
      @lstat.uid
    end
    
    def group
      @lstat.gid
    end
    
  end
end
