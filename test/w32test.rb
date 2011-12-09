$:.unshift(File.join(File.dirname(__FILE__), "../ruby"))

require 'rubygems'
require 'windows/api'
require 'windows/file'
require 'windows/security'
require 'windows/handle'

include Windows::File
include Windows::Security
include Windows::Handle


def get_owner(file)
  hFile = CreateFile(
    file,
    GENERIC_READ,
    FILE_SHARE_READ,
    nil,
    OPEN_EXISTING,
    FILE_ATTRIBUTE_NORMAL,
    nil
  )

  # check for null


  # 28 indicated
  sid = 0.chr * 60
  sid_ptr = [0].pack('L')
  
  rv = GetSecurityInfo(
    hFile,
    SE_FILE_OBJECT,
    OWNER_SECURITY_INFORMATION,
    sid_ptr,
    nil,
    nil,
    nil,
    nil
  )
  
  # 80 indicated
  name_buf = 0.chr * 100
  name_cch = [name_buf.size].pack('L')
  
  domain_buf = 0.chr * 100
  domain_cch = [domain_buf.size].pack('L')
  sid_name = 0.chr * 4
  
  LookupAccountSid(
    nil,
    sid_ptr.unpack('L').first,
    name_buf,
    name_cch,
    domain_buf,
    domain_cch,
    sid_name
  )
  
  #puts name_buf.strip
  #puts domain_buf.strip
  
  CloseHandle(hFile)

  return domain_buf.strip + '\\' + name_buf.strip
end

def get_owner2(file)
  current_length = 0
  length_needed  = [0].pack('L')
  sec_buf = ''

  loop do
    bool = GetFileSecurity(
      file,
      OWNER_SECURITY_INFORMATION,
      sec_buf,
      sec_buf.length,
      length_needed
    )

    if bool == 0 && GetLastError() != ERROR_INSUFFICIENT_BUFFER
      raise ArgumentError, get_last_error
    end
        
    break if sec_buf.length >= length_needed.unpack('L').first
    ln = length_needed.unpack('L').first
    puts ln
    sec_buf += ' ' * (ln * 2)
  end

  sid = 0.chr * 60
  sid_ptr  = [0].pack('L')
  revision = 0
  revision_ptr = [revision].pack('L')

  unless GetSecurityDescriptorOwner(
      sec_buf,
      sid_ptr,
      revision)
    raise ArgumentError, get_last_error
  end

  puts "Done S"
  
  name_buf = 0.chr * 100
  name_cch = [name_buf.size].pack('L')

  domain_buf = 0.chr * 100
  domain_cch = [domain_buf.size].pack('L')
  sid_name = 0.chr * 4

  LookupAccountSid( 
    nil,
    sid_ptr.unpack('L').first,
    name_buf,
    name_cch,
    domain_buf,
    domain_cch,
    sid_name
  )
  
  CloseHandle(hFile)
  
  return domain_buf.strip + '\\' + name_buf.strip
end

require 'ret/afile/win32/fileinfo'

puts Ret::Afile::Win32::Fileinfo.basic_test

dir = Dir.new("C:\\Users\\jelkins")
dir.each do |f|
  #if !File.directory?(File.join(dir.path, f))
    puts f + ": " + Ret::Afile::Win32::Fileinfo.get_owner(dir.path + "\\" + f) if f[0,1] != '.'
  #end
end


