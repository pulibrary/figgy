# frozen_string_literal: true
class MultiChecksum < Valkyrie::Resource
  attribute :sha256, Valkyrie::Types::SingleValuedString
  attribute :md5, Valkyrie::Types::SingleValuedString
  attribute :sha1, Valkyrie::Types::SingleValuedString
end
