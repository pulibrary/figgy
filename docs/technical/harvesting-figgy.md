# Collection Discovery

We publish a collection manifest of all Figgy collections at:

    https://figgy.princeton.edu/iiif/collections/

This manifest includes an entry for each Figgy collection, including a label, and the collection manifest URL.

# Item Discovery

Each collection manifest includes an entry for each item in the collection, including a label, thumbnail, and the item manifest URL.

# Item Information

Each item manifest contains metadata (both a `metadata` hash, and JSON-LD and typically either EAD or MARC XML in `seeAlso`), images or other media, a thumbnail, and a license statement.  Most objects also include links to download each page image, and to download the entire object as a PDF.