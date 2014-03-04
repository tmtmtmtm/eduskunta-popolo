eduskunta-popolo
================

Build and manage Popolo-compliant JSON for the Finnish Parliament.

----

HTML is spidered from the Eduskunta.fi site into `data/MPs/html`

Then, to generate JSON from that HTML:

    for i in `basename -s .html data/MPs/html/*.html`; do; ruby -Ilib scrapers/get_mp_data data/MPs/html/$i.html > data/MPs/json/$i.json; done

Then combine those into `people.json`:

    ruby -I lib bin/combined_json data/MPs/json > people.json
