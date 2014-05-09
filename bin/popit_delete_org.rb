#!/usr/bin/ruby 

require 'popit'

id = ARGV[0] or abort "Usage: #{$0} <id> <password>"
password = ARGV[1] or abort "Usage: #{$0} <id> <password>"

api = PopIt.new :instance_name => 'eduskunta', :user => 'tony@micropiphany.com', :password => password

o = api.organizations(id).get or abort "No such record"
puts "Deleting #{o['id']}"

o['memberships'].each do |m|
  puts "Deleting membership #{m['id']}"
  api.memberships(m['id']).delete
end

api.organizations(id).delete



