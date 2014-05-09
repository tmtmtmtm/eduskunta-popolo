#!/usr/bin/ruby 

require 'popit'

password = ARGV[0] or abort "Usage: #{$0} <password>"

api = PopIt.new :instance_name => 'eduskunta', :user => 'tony@micropiphany.com', :password => password

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



