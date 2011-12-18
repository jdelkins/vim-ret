$:.unshift(File.join(File.dirname(__FILE__), "../ruby"))
  
require 'ret'
include Ret

name = ARGV.count > 0 ? ARGV.first : "#{ENV["USERPROFILE"]}\\vimfiles\\bundle\\fugitive" 

fs = Fileset.new(name, skipdots=true)
fs.list.each {|l| puts l}

puts "\nEXPAND\n"
fs.expand
fs.list.each {|l| puts l}

fs.rebase("../.\\command-t\\./..\\lusty\\.")
puts "\nREBASE: #{fs.basedir}\n"
fs.list.each {|l| puts l}

