module Ret
  def self.version
    "0.1"
  end
  
  def self.platform
    if ENV['OS'] == 'Windows_NT' && !RUBY_PLATFORM[/cygwin/]
      :Windows
    else
      :Unix
    end
  end
end

require 'ret/fileset'
require 'ret/afile'
