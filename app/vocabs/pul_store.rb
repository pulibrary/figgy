# frozen_string_literal: true
require 'rdf'
class PULStore < RDF::StrictVocabulary('http://princeton.edu/pulstore/terms/')
  term :barcode, label: 'Barcode', type: 'rdf:Property'
  term :physicalNumber, label: 'Physical Number', type: 'rdf:Property'
  term :sortOrder, label: 'Sort Order', type: 'rdf:Property'
  term :state, label: 'State', type: 'rdf:Property'
  term :suppressed, label: 'Suppressed', type: 'rdf:Property'
end
