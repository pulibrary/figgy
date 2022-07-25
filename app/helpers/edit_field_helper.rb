# frozen_string_literal: false
module EditFieldHelper
  def reorder_languages(languages, top_languages)
    pull_to_front(languages) { |term| top_languages.include? term }
  end

  def render_edit_field_partial(field_name, locals)
    collection = locals[:f].object.model_name.collection
    render_edit_field_partial_with_action(collection, field_name, locals)
  end

  private

    def pull_to_front(array, &block)
      temp = array.select(&block)
      array.reject!(&block)
      temp + array
    end

    # This finds a partial based on the record_type and field_name
    # if no partial exists for the record_type it tries using "records" as a default
    def render_edit_field_partial_with_action(record_type, field_name, locals)
      partial = find_edit_field_partial(record_type, field_name)
      render partial, locals.merge(key: field_name)
    end

    def find_edit_field_partial(record_type, field_name)
      ["#{record_type}/edit_fields/_#{field_name}", "records/edit_fields/_#{field_name}",
       "#{record_type}/edit_fields/_default", "records/edit_fields/_default"].find do |partial|
         logger.debug "Looking for edit field partial #{partial}"
         return partial.sub(/\/_/, "/") if partial_exists?(partial)
       end
    end

    def partial_exists?(partial)
      lookup_context.find_all(partial).any?
    end
end
