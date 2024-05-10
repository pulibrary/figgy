# frozen_string_literal: true
class PcdmUse
  OriginalFile = RDF::URI.new("http://pcdm.org/use#OriginalFile")
  PreservationFile = RDF::URI.new("http://pcdm.org/use#PreservationFile")
  IntermediateFile = RDF::URI.new("http://pcdm.org/use#IntermediateFile")
  ServiceFile = RDF::URI.new("http://pcdm.org/use#ServiceFile")
  ServiceFilePartial = RDF::URI.new("http://pcdm.org/use#ServiceFileParti")
  Caption = RDF::URI.new("http://pcdm.org/use#Caption")
  CloudDerivative = RDF::URI.new("http://pcdm.org/use#CloudDerivative")
  ThumbnailImage = RDF::URI.new("http://pcdm.org/use#ThumbnailImage")
  # Deprecated
  PreservationMasterFile = RDF::URI.new("http://pcdm.org/use#PreservationMasterFile")
end
