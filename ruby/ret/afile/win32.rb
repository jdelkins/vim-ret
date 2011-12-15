require 'ret/afile/win32/fileinfo'

module Ret
  class Afile

    def subinit(path)
      @fileinfo = Win32::Fileinfo.new(path)
    end
    
    def listing(format)
      sprintf(format.join(" "), @fileinfo.attributes.to_s, @fileinfo.owner, @fileinfo.size, @fileinfo.mtime.strftime("%F %H:%M"), @name)
      # TODO: symlink checking
    end
    
    def owner
      @fileinfo.owner
    end
    
    def size
      @fileinfo.size
    end
    
    def attributes
      @fileinfo.attributes
    end
    
    def mtime
      @fileinfo.mtime
    end
    
    def ctime
      @fileinfo.ctime
    end
    
    def atime
      @fileinof.atime
    end
  end
end
