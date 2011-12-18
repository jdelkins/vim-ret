module Ret
  class Afile
      
    class Perm
      None = '-'
      Read = 'r'
      Write = 'w'
      Execute = 'x'
      ExecSetUid = 's'
      SetUid = 'S'
      Sticky = 't'
    end
    
    def subinit()
      file = File.join(@basedir, @relpath)
      @lstat = File.lstat(file)
      if File.symlink?(file)
        @target = File.readlink(file)
        @target_stat = File.stat(@target)
      end
    end

    def directory?()
      @lstat.directory?
    end

    def hidden?()
      File.basename(@relpath).start_with? '.'
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
