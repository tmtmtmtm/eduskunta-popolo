#!/usr/bin/ruby 

require 'popit'

key = ARGV[0] or abort "Usage: #{$0} <apikey>"

api = PopIt.new instance_name: 'eduskunta', apikey: key

%w(memberships organizations persons).each do |type|
  records = api.public_send(type).get(per_page: 100)
  puts "#{records.count} #{type} to delete"
  records.each do |record| 
    puts "  Removing #{type} #{record['id']} <#{record.class}>"
    api.public_send(type, record['id']).delete
  end
end

