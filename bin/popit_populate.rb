#!/usr/bin/ruby 
# populate an empty PopIt instance

require 'popit'

password = ARGV[0] or abort "Usage: #{$0} <password>"

api = PopIt.new :instance_name => 'eduskunta', :user => 'tony@micropiphany.com', :password => password

parties = JSON.parse(File.read('parties.json'))

puts "#{parties.size} parties to add"
parties.each { |p| 
  puts "  Putting #{p['id']}"
  api.organizations.post(p) 
}

people = JSON.parse(File.read('people.json'))
puts "#{people.size} people to add"
people.each { |p| 
  puts "  Putting #{p['id']}"
  # TODO If we don't have our own ID use the one get one back for the memberships
  api.persons.post(p); 

  p['memberships'].each { |m| 
    m['person_id'] = p['id'];
    puts "  Membership: #{m}"
    api.memberships.post(m)
  }
}



