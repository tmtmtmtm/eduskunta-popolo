#!/usr/bin/ruby

# Fetch voting information from the KansanMuisti API
# and output as nested JSON

require 'json'
# require 'open-uri'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '/tmp/open-uri'

psid = ARGV[0] or raise "Usage: #{$0} <plenary session id>"
@SKIP = ['plenary_session', 'id', 'resource_uri', 'last_checked_time', 'last_modified_time']

def api_fetch (str)
  api = "http://dev.kansanmuisti.fi/api/v1"
  url = "#{api}#{str}"
  # puts "** FETCH #{url} **"
  json = JSON.parse(open(url).read)
end

def plenary_session (id)
  j = api_fetch("/plenary_session/#{id}/")
  j['plenary_votes'].map! { |uri| 
    plenary_vote( uri[/plenary_vote\/(\d+)/,1] )
  }
  return j.delete_if { |k,v| @SKIP.include? k }
end

def plenary_session_item (id)
  j = api_fetch("/plenary_session_item/#{id}/")
  return j.delete_if { |k,v| [@SKIP, 'plenary_votes'].flatten.include? k }
end

def rollcall (pvid)
  j = api_fetch("/vote/?limit=200&plenary_vote=#{pvid}")
  j['objects'].map { |h| h.delete_if { |k,v| [@SKIP, 'plenary_vote'].flatten.include? k } }
end

def plenary_vote (id)
  j = api_fetch("/plenary_vote/#{id}/")
  j['session_item'] = plenary_session_item(j['session_item'][/plenary_session_item\/(\d+)/,1])
  j['roll_call'] = rollcall(id)
  return j.delete_if { |k,v| @SKIP.include? k }
end

ps_j = plenary_session(psid)
puts JSON.pretty_generate( ps_j )

