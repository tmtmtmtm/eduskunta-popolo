var fs = require('fs'),
    util = require('util'),
    _ = require('underscore'),
    parseArgs = require('minimist');

var VOTE_CHOICES = {
  'Y': 'yes',
  'N': 'no',
  'A': 'absent',
  'E': 'abstain',
  'S': 'S'
};


var transformMotions = function(file_name, voterToPeople) {
  var data = fs.readFileSync(file_name, 'utf8');
  session = JSON.parse(data);
  var motions = [];
  session.id = session.origin_id.replace('/', '-');
  session.plenary_votes.forEach(function(plenary_vote, i) {
    var motion = transformMotion(plenary_vote, session, i+1, voterToPeople);
    motions.push(motion);
  });
  return motions;
};

var transformMotion = function(plenary_vote, session, motion_idx, voterToPeoples) {
  var motion_id = 'motion-' + session.id + '-' + motion_idx;
  var motion = {
    '@type': 'Motion',
    'organization-id': 'finnish-parliament',
    'organization': {
      'name': 'Finnish Parliament'
    },
    'context': {
      'sitting': session.origin_id
    },
    'sources': {
      'url': session.info_link
    },
    'text': plenary_vote.subject,
    'motion_id': motion_id,
    'date': session.date,
    'requirement': plenary_vote.setting,
    'result': 'unknown',
    'vote_events': []
  };

  var vote_event = {
    '@type': 'VoteEvent',
    'identifier': motion_id.replace('motion', 'vote-event'),
    'motion': { 'text': motion.text },
    'start_date': motion.date,
    'end_date': motion.date,
    'counts': [],
    'votes': [],
  };

  _.each(plenary_vote.vote_counts, function(c, k) {
    vote_event.counts.push({
      '@type': 'Count',
      'option': VOTE_CHOICES[k],
      'value': c
    });
  });

  plenary_vote.roll_call.forEach(function(r) {
    var voter_id = r.member.replace('/api/v1/member/', '').replace('/', '');
    vote_event.votes.push({
      '@type': 'Vote',
      'option': VOTE_CHOICES[r.vote],
      'party_id': 'popit.eduskunta/party/' + r.party,
      'voter_id': voterToPeople[voter_id],
      'vote_event_id': vote_event.identifier
    });
  });

  motion.vote_events.push(vote_event);
  return motion;
};


var partiesData = JSON.parse(fs.readFileSync('../parties.json', 'utf-8'));
var peopleData = JSON.parse(fs.readFileSync('../people.json', 'utf-8'));

var parties = {};
partiesData.forEach(function(e) {
  parties[e.id] = e;
});

var people = {}, voterToPeople = {};
peopleData.forEach(function(p) {
  people[p.id] = p;
  p.identifiers.forEach(function(id) {
    if (id.scheme == 'kansanmuisti.fi') {
      voterToPeople[id.identifier] = p.id;
    }
  });
});

var args = parseArgs(process.argv.slice(2));
var motions = [];
args._.forEach(function(file_name) {
  motions = motions.concat(transformMotions(file_name, voterToPeople));
});
console.log(motions.length);

var data = {
  'motions': motions,
  'parties': parties,
  'people': people
  };
fs.writeFileSync('motions.json', JSON.stringify(data));
