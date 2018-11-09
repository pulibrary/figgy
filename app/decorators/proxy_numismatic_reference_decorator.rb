# frozen_string_literal: true
class ProxyNumismaticReferenceDecorator < Valkyrie::ResourceDecorator
  def to_s
    "#{numismatic_reference_id}, #{part} #{number}"
  end
end
