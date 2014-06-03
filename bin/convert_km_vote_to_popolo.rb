#!/usr/bin/ruby

# Convert a KM session JSON file (e.g. in /data) into Popolo JSON 
# of a list of motions (with embedded vote_events) from that session.
# Requires a people.json and parties.json in the current directory

require 'json'
require 'colorize'

sessionfile = ARGV[0] or raise "Usage: #{$0} <filename>"
json = JSON.parse(File.open(sessionfile).read)

# TODO provide options for these
@jpeople = JSON.parse(File.open('people.json').read)
@jparties = JSON.parse(File.open('parties.json').read)

@vote_choices = {
  'Y' => 'yes',
  'N' => 'no',
  'A' => 'absent',
  'E' => 'abstain',
};

def convert_vote_counts (votes)
  return votes.collect { |k, v|
    { option: @vote_choices[k], value: v } 
  }.select { |c| !c[:option].nil? }.reverse
end

def member_id_for (kmperson)
  kid = kmperson[/(\d+)\/$/, 1]
  person = @jpeople.find { |p| 
    p["identifiers"].find { |i|
      i["scheme"] == 'kansanmuisti.fi' and
      i["identifier"] == kid
    }
  }
  raise "No such person: #{kid}" if person.nil?
  return person['id']
end

def party_id_for (kmparty)
  party = @jparties.find { |p| p['id'].end_with? "/#{kmparty}" }
  raise "No such party: #{kmparty}" if party.nil?
  return party['id']
end

def convert_roll_call (votes)
  votes.map { |vote|
    {
      voter_id: member_id_for( vote['member'] ),
      party_id: party_id_for( vote['party'] ),
      option:   @vote_choices[ vote['vote'] ],
    }
  }
end


session = json.delete('origin_id')
session_date = json.delete('date')
session_src  = json.delete('info_link')

motions = json['plenary_votes'].map { |pv|
  motion_id = "PTK-#{session.gsub('/','-')}-#{ pv.delete('number') }"

  motion = {
    id: motion_id,
    organization_id: 'popit.eduskunta/organization/eduskunta',
    context: { 
      sitting: session,
      date: session_date,
      sources: [{ url: session_src }],
    },
    object: {
      bill:  pv['session_item'].delete('description'),
      subject:  pv.delete('subject'),
      stage: pv['session_item'].delete('processing_stage'),
      type:  pv['session_item'].delete('type'),
      sub_description:  pv['session_item'].delete('sub_description'),
      type:  pv['session_item'].delete('sub_number'),
    }.select { |k, v| !v.nil? },
    text: pv.delete('setting'),
    vote_events: [{
      motion_id: motion_id,
      start_date: pv.delete('time'),
      counts: convert_vote_counts( pv.delete('vote_counts') ),
      votes: convert_roll_call( pv.delete('roll_call') ),
    }],
  }

  %w( documents nr_statements nr_votes number  ).each { |skip| pv['session_item'].delete(skip) }
  raise "Unhandled #{pv['session_item']}" unless pv['session_item'].empty?
  %w( session_item info_link ).each { |skip| pv.delete(skip) }
  raise "Unhandled #{pv}" unless pv.empty?
  motion
}

%w( plenary_votes origin_version name url_name  ).each { |skip| json.delete(skip) }
raise "Unhandled #{json}" unless json.empty?

puts JSON.pretty_generate ( motions )
