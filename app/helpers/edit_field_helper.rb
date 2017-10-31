# frozen_string_literal: false
module EditFieldHelper
  def reorder_languages(languages)
    front_languages = %w[English Portuguese Spanish]
    pull_to_front(languages) { |term| front_languages.include? term.label }
  end

  private

    def pull_to_front(array, &block)
      temp = array.select(&block)
      array.reject!(&block)
      temp + array
    end
end
