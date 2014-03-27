eduskunta-popolo
================

Build and manage Popolo-compliant JSON for the Finnish Parliament.

----

HTML is spidered from the Eduskunta.fi site into `data/MPs/html`

Then, to generate JSON from that HTML:

    for i in `basename -s .html data/MPs/html/*.html`; do; ruby -Ilib scrapers/get_mp_data data/MPs/html/$i.html > data/MPs/json/$i.json; done

Then combine those into `people.json`:

    ruby -I lib bin/combined_json data/MPs/json > people.json

`data/oldMPs` contains records of all historic MPs as well, but as these
aren't availabe in English, I'm still rewriting the parser to handle
the Finnish (as well as all the old party names, cabinet positions, etc)
