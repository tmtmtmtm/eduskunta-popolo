eduskunta-popolo
================

Build and manage Popolo-compliant JSON for the Finnish Parliament.

----

1. Fetch the data from KansanMuisti
  * `pushd data/kansanmuisti ; curl -K curlrc; popd`
  * Optionally create pretty-printed versions for easier diffs (e.g. `jq '.' member.json > member.pp.json`)

2. Generate the party JSON
  * `bin/generate_party_list > parties.json`

3. Regenerate the people JSON
  * `bin/generate_persons data/kansanmuisti/member.json > people.json`

4. Regenerate the coalitions JSON
  * `bin/generate_coalitions > coalitions.json`

5. Build a complete set of JSON
  * `bin/generate_popit_data > eduskunta.json`

6. Rebuild the PopIt
  * `bin/repopulate_popit <APIKEY>`


---


Fetch all the vote data
  * `bin/find-sessions-with-votes.rb data/kansanmuisti/plenary*.pp.json | sh`

