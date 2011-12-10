$:.unshift(File.join(File.dirname(__FILE__), "../ruby"))
  
require 'ret'
include Ret

fs = Fileset.new("C:\\Users\\jde.ELKINS")
fs.list.each {|l| puts l}