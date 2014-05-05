eduskunta-popolo
================

Build and manage Popolo-compliant JSON for the Finnish Parliament.

----

1. Fetch the data from KansanMuisti
  * `pushd data/kansanmuisti ; curl -K curlrc; popd`

2. Regenerate the people JSON
  * `bin/generate_persons data/kansanmuisti/member.json > people.json`

