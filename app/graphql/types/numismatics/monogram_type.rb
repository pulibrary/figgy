# frozen_string_literal: true
class Types::Numismatics::MonogramType < Types::BaseObject
  implements Types::Resource

  def label
    Array.wrap(object.title).first
  end
end
