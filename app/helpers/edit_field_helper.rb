# frozen_string_literal: false

module EditFieldHelper
  def reorder_languages(languages, top_languages)
    pull_to_front(languages) { |term| top_languages.include? term }
  end

  private

    def pull_to_front(array, &block)
      temp = array.select(&block)
      array.reject!(&block)
      temp + array
    end
end
