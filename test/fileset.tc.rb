$:.unshift(File.join(File.dirname(__FILE__), "../ruby"))
puts $:.join(', ')

require('ret/fileset')
require('ret/afile')

x = Ret::Fileset.new_from_directory("C:/Users/jelkins/vimfiles")
x.afiles().each do |af|
  puts af.listing
end