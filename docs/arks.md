# ARKs

[ARKs](https://wiki.lyrasis.org/display/ARKs/ARK+Identifiers+FAQ) are persistent identifiers that we mint through the [ezid service](https://ezid.cdlib.org/). They provide permanent link urls whose targets we can change over time if we move our materials.

## Syncing ARKs from the catalog
If a MARC record has an ark, [figgy pulls it into the identifier field](https://github.com/pulibrary/figgy/blob/1a545e06ace6e07acbee89f5753c78132208e972/app/change_set_persisters/change_set_persister/apply_remote_metadata.rb#L49) so as not to mint a new ark for a resource that already has one. Figgy gets the identifiers from the [bibdata jsonld endpoint](https://github.com/pulibrary/figgy/blob/1a545e06ace6e07acbee89f5753c78132208e972/app/models/remote_record.rb#L93)
