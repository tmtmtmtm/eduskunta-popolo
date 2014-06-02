#!/usr/bin/env ruby

# Work out which sessions have votes that need to be fetched.

# Usage: $0 <files>
# e.g. bin/find-sessions_with-votes.rb data/kansanmuisti/plenary*.pp.json

# You can pipe the output of this into find-sessions-with-votes.rb (see README.md)

require 'json'

ARGV.each do |file|
  sessions = JSON.parse( IO.read (file) )['objects']
  sessions.each do |session|
    puts "bin/fetch_km_votes.rb #{session['id']} > data/kansanmuisti/session_votes/session-#{session['id']}.json" unless session['plenary_votes'].empty? 
  end
end
