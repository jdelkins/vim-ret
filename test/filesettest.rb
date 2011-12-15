$:.unshift(File.join(File.dirname(__FILE__), "../ruby"))
  
require 'ret'
include Ret

name = ARGV.count > 0 ? ARGV.first : ENV["USERPROFILE"]

fs = Fileset.new(name)
fs.list.each {|l| puts l}
