# Loads mkmf which is used to make makefiles for Ruby extensions
require 'mkmf'

# Give it a name
extension_name = 'fileinfo'

def missing item
  puts "couldn't find #{item} (required)"
  exit 1
end

have_header('ruby.h') or missing 'ruby.h'
create_makefile('fileinfo')
