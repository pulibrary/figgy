# frozen_string_literal: true
class PcdmUse
  OriginalFile = RDF::URI.new("http://pcdm.org/use#OriginalFile")
  PreservationFile = RDF::URI.new("http://pcdm.org/use#PreservationFile")
  PreservedMetadata = RDF::URI.new("http://pcdm.org/use#PreservedMetadata")
  PreservationCopy = RDF::URI.new("http://pcdm.org/use#PreservationCopy")
  IntermediateFile = RDF::URI.new("http://pcdm.org/use#IntermediateFile")
  ServiceFile = RDF::URI.new("http://pcdm.org/use#ServiceFile")
  ServiceFilePartial = RDF::URI.new("http://pcdm.org/use#ServiceFilePartial")
  Caption = RDF::URI.new("http://pcdm.org/use#Caption")
  CloudDerivative = RDF::URI.new("http://pcdm.org/use#CloudDerivative")
  ThumbnailImage = RDF::URI.new("http://pcdm.org/use#ThumbnailImage")
  # Deprecated
  PreservationMasterFile = RDF::URI.new("http://pcdm.org/use#PreservationMasterFile")
end
