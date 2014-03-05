#!/usr/bin/ruby 

require 'popit'

password = ARGV[0] or abort "Usage: #{$0} <password>"

api = PopIt.new :instance_name => 'eduskunta', :user => 'tony@micropiphany.com', :password => password

%w(memberships organizations persons).each do |type|
  api.public_send(type).get.each do |record| 
    puts "  Removing #{type} #{record['id']} <#{record.class}>"
    api.public_send(type, record['id']).delete
  end
end

