#!/usr/bin/ruby 

require 'popit'

id = ARGV[0] or abort "Usage: #{$0} <id> <apikey>"
key = ARGV[1] or abort "Usage: #{$0} <id> <apikey>"

api = PopIt.new instance_name: 'eduskunta', :apikey: key

api.persons(id).get or abort "No such record"
api.persons(id).delete


