# frozen_string_literal: true
class SolrNode < ApplicationDecorator
  def id
    "id-#{super}"
  end
end
