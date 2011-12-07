require 'rubygems'
require 'win32/file'

module Ret
  class Afile
    def listing
      x = "#{typecode} #{attributes} #{permissions} #{@lstat.size} #{@name}"
      # TODO: symlink checking
      return x
    end
    
    private
    
    def permissions
      interesting_perms = File.get_permissions(File.join(@dirname, @name)).select do | user, mask |
        not user.to_s()[/CREATOR OWNER|BUILTIN\\|NT AUTHORITY\\|NT SERVICE/]
      end
      converted = interesting_perms.map do | user, mask |
        "#{user}:#{File.securities(mask)}"
      end
      converted.nil? ? "SYSTEM" : converted.join(" ")
    end
    
    def attributes
      File.attributes(File.join(@dirname, @name)).join()
    end
  end
  
end
