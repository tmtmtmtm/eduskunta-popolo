#!/usr/bin/env ruby

#
# find sessions with votes
# grab those votes
#

require 'json'
require 'english'

def find_sessions_with_votes(sessions)
  for session in sessions
    if not session['plenary_votes'].empty?
      puts session['id']
    end
  end
end

find_sessions_with_votes(JSON.parse(STDIN.read())['objects'])
