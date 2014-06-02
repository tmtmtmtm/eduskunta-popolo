#!/usr/bin/ruby 

require 'popit'

id = ARGV[0] or abort "Usage: #{$0} <id> <password>"
password = ARGV[1] or abort "Usage: #{$0} <id> <password>"

api = PopIt.new :instance_name => 'eduskunta', :user => 'tony@micropiphany.com', :password => password

api.persons(id).get or abort "No such record"
api.persons(id).delete


