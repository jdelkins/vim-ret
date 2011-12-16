$:.unshift(File.join(File.dirname(__FILE__), "../ruby"))
puts $:.join(', ')

require('ret/fileset')
require('ret/afile')

def ls(dir)
  fs = Ret::Fileset.new dir
  fs.afiles().each do |af|
    #puts af.name
    puts af.listing
  end
end

ls ENV["USERPROFILE"]
