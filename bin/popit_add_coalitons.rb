#!/usr/bin/ruby 

require 'popit'

apikey = ARGV[0] or abort "Usage: #{$0} <apikey>"

api = PopIt.new instance_name: 'eduskunta', apikey: apikey

cs = JSON.parse(File.read('coalitions.json'))

cs.each { |c| 
  ms = c.delete('memberships')
  puts "Putting #{c}"
  api.organizations.post(c); 

  ms.each { |m| 
    m['organization_id'] = c['id'];
    puts "  Membership: #{m}"
    api.memberships.post(m)
  }
}



