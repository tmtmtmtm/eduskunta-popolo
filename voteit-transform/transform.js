var fs = require('fs'),
    util = require('util'),
    _ = require('underscore'),
    parseArgs = require('minimist');

var VOTE_CHOICES = {
  'Y': 'yes',
  'N': 'no',
  'A': 'abstain',
  'E': 'E',
  'S': 'S'
};

var readData = function(file_name) {
  var data = fs.readFileSync(file_name, 'utf8');
  sessionData = JSON.parse(data);
  return transformSession(sessionData);
};

var transformSession = function(session) {
  var motions = [];
  session.id = session.origin_id.replace('/', '-');
  session.plenary_votes.forEach(function(plenary_vote, i) {
    var motion = transformMotion(plenary_vote, session, i+1);
    motions.push(motion);
  });
  return motions;
};

var transformMotion = function(plenary_vote, session, motion_idx) {
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
    'object_id': motion_id,
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
    vote_event.votes.push({
      '@type': 'Vote',
      'option': VOTE_CHOICES[r.vote],
      'party_id': r.party,
      'voter_id': r.member,
      'vote_event_id': vote_event.identifier
    });
  });

  motion.vote_events.push(vote_event);
  return motion;
};


var args = parseArgs(process.argv.slice(2));
var motions = [];
args._.forEach(function(file_name) {
  motions = motions.concat(readData(file_name));
});
console.log(motions.length);
fs.writeFileSync('motions.json', JSON.stringify({'motions': motions}));



