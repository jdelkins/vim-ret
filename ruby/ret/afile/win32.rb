require 'ret/afile/win32/fileinfo'

module Ret
  class Afile

    def subinit()
      @fileinfo = Win32::Fileinfo.new(pathname)
    end
    
    def directory?()
      @fileinfo.attributes.include? :FILE_ATTRIBUTE_DIRECTORY
    end

    def hidden?()
      (@fileinfo.attributes.include? :FILE_ATTRIBUTE_HIDDEN) or (File.basename(@relpath).start_with? '.')
    end

    def listing(format)
      sprintf(format.join(" "), @fileinfo.attributes.to_s, @fileinfo.owner, @fileinfo.size, @fileinfo.mtime.strftime("%F %H:%M"), relpath)
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
