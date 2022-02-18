# frozen_string_literal: true

require "rdf"
class PULStore < RDF::StrictVocabulary("http://princeton.edu/pulstore/terms/")
  term :barcode, label: "Barcode", type: "rdf:Property"
  term :physicalNumber, label: "Physical Number", type: "rdf:Property"
  term :sortOrder, label: "Sort Order", type: "rdf:Property"
  term :sortTitle, label: "Sort Title", type: "rdf:Property"
  term :state, label: "State", type: "rdf:Property"
  term :earliestCreated, label: "Earliest Created", type: "rdf:Property"
  term :latestCreated, label: "Latest Created", type: "rdf:Property"
  term :suppressed, label: "Suppressed", type: "rdf:Property"
  term :heightInCM, label: "Height in CM", type: "rdf:Property"
  term :widthInCM, label: "Width in CM", type: "rdf:Property"
  term :isPartOfSeries, label: "Is Part Of Series", type: "rdf:Property"
  term :pageCount, label: "Page Count", type: "rdf:Property"
  term :trackingNumber, label: "trackingNumber", type: "rdf:Property"
  term :shippedDate, label: "shippedDate", type: "rdf:Property"
  term :receivedDate, label: "receivedDate", type: "rdf:Property"
  term :state, label: "state", type: "rdf:Property"
end
