# frozen_string_literal: true
module Valhalla
  module ApplicationHelper
    def visibility_badge(value)
      Valhalla::PermissionBadge.new(value).render
    end

    # Generates the markup for a form field for a metadata attribute
    # (Deprecates form partials used by hydra-editor)
    # @param field_name [Symbol] the field name
    # @param form [SimpleForm::FormBuilder] the SimpleForm builder Object
    # @return [String] the markup
    def render_edit_field_markup(field_name, form)
      render_method = "render_#{field_name}".to_sym
      markup = if respond_to? render_method
                 send render_method, field_name, form
               else
                 render_default field_name, form
               end
      markup.html_safe
    rescue StandardError => error
      logger.warn error
      ''
    end

    # Generates form field markup for generic metadata attributes
    # @param key [Symbol] the field name
    # @param f [SimpleForm::FormBuilder] the SimpleForm builder Object
    # @return [String] the markup
    def render_default(key, f)
      return f.input(key, as: :multi_value, input_html: { class: 'form-control' }, required: f.object.required?(key)) if f.object.multiple?(key)
      f.input key, required: f.object.required?(key)
    end

    # Generates form field markup for child resource IDs
    # @param _key [Symbol] the field name
    # @param f [SimpleForm::FormBuilder] the SimpleForm builder Object
    # @return [String] the markup
    def render_append_id(_key, f)
      f.input :append_id, as: :hidden
    end

    # Generates form field markup for barcodes
    # @param _key [Symbol] the field name
    # @param f [SimpleForm::FormBuilder] the SimpleForm builder Object
    # @return [String] the markup
    def render_barcode(_key, f)
      current_barcode = @change_set.barcode if @change_set
      f.input :barcode, label: 'Barcode', input_html: { class: 'detect-duplicates', data: { value: current_barcode, field: 'barcode_ssim', model: f.object.model.class.to_s } }
    end

    # Generates form field markup for spatial coverage values
    # @param _key [Symbol] the field name
    # @param f [SimpleForm::FormBuilder] the SimpleForm builder Object
    # @return [String] the markup
    def render_coverage(_key, f)
      hidden_coverage_element = f.input(:coverage, as: :hidden)
      coverage_element = bbox_input(:coverage, @change_set)

      label_element = content_tag(:label, 'Coverage', class: ['control-label', 'text', 'optional'], for: 'scanned_map_coverage')

      label_element + hidden_coverage_element + coverage_element
    end

    # Generates form field markup for resource creation dates
    # @param key [Symbol] the field name
    # @param f [SimpleForm::FormBuilder] the SimpleForm builder Object
    # @return [String] the markup
    def render_date_created(key, f)
      date_created_element = render_default(key, f)

      date_start_element = nil
      date_end_element = nil
      f.simple_fields_for(:date_range_form, wrapper: :inline_form) do |g|
        date_start_element = g.input(:start, required: g.object.required?(:start))
        date_end_element = g.input(:end, required: g.object.required?(:end))
      end

      left_column_element = content_tag(:div, date_start_element, class: 'col-md-6')
      right_column_element = content_tag(:div, date_end_element, class: 'col-md-6')
      children = left_column_element + right_column_element
      row_element = content_tag(:div, children, class: 'row')

      date_created_element + row_element
    end

    # Generates form field markup for resource descriptions
    # @param key [Symbol] the field name
    # @param f [SimpleForm::FormBuilder] the SimpleForm builder Object
    # @return [String] the markup
    def render_description(key, f)
      if f.object.multiple? key
        return f.input(:description,
                       as: :multi_value,
                       input_html: { rows: '7', type: 'textarea' },
                       required: f.object.required?(key))
      end

      f.input(:description, as: :text, input_html: { rows: '7' }, required: f.object.required?(key))
    end

    # Generates form field markup for EphemeraField names
    # @param key [Symbol] the field name
    # @param f [SimpleForm::FormBuilder] the SimpleForm builder Object
    # @return [String] the markup
    def render_field_name(key, f)
      f.input(:field_name,
              label: 'Name',
              as: :select,
              collection: ControlledVocabulary.for(:ephemera_field).all,
              label_method: :label,
              value_method: :value,
              input_html: {
                class: 'form-control rights-statement',
                data: {
                  notable: ControlledVocabulary.for(:ephemera_field).all.select(&:notable?).map(&:value)
                }
              },
              required: f.object.required?(key))
    end

    # Generates form field markup for resource genres
    # @param key [Symbol] the field name
    # @param f [SimpleForm::FormBuilder] the SimpleForm builder Object
    # @return [String] the markup
    def render_genre(key, f)
      if @genre.present?
        f.input(:genre,
                label: 'Genre',
                as: :select,
                collection: @genre,
                label_method: :label,
                value_method: :id,
                input_html: {
                  multiple: f.object.multiple?(key)
                },
                required: f.object.required?(key))
      elsif f.object.multiple? key
        f.input(key,
                as: :multi_value,
                input_html: { class: 'form-control' },
                required: f.object.required?(key))
      else
        f.input key, required: f.object.required?(key), class: 'foo'
      end
    end

    # Generates form field markup for geospatial subjects
    # @param key [Symbol] the field name
    # @param f [SimpleForm::FormBuilder] the SimpleForm builder Object
    # @return [String] the markup
    def render_geo_subject(key, f)
      if @geo_subject.present?
        f.input(:geo_subject,
                label: 'Geo subject',
                as: :select,
                collection: @geo_subject,
                label_method: :label,
                value_method: :id,
                input_html: {
                  multiple: f.object.multiple?(key)
                },
                required: f.object.required?(key))
      elsif f.object.multiple? key
        f.input(key,
                as: :multi_value,
                input_html: { class: 'form-control' },
                required: f.object.required?(key))
      else
        f.input key, required: f.object.required?(key), class: 'foo'
      end
    end

    # Generates form field markup for geographic origins of resources
    # @param key [Symbol] the field name
    # @param f [SimpleForm::FormBuilder] the SimpleForm builder Object
    # @return [String] the markup
    def render_geographic_origin(key, f)
      if @geographic_origin.present?
        f.input(:geographic_origin,
                label: 'Geographic origin',
                as: :select,
                collection: @geographic_origin,
                label_method: :label,
                value_method: :id,
                input_html: {
                  multiple: f.object.multiple?(key)
                },
                required: f.object.required?(key))
      elsif f.object.multiple? key
        f.input(key,
                as: :multi_value,
                input_html: { class: 'form-control' },
                required: f.object.required?(key))
      else
        f.input key, required: f.object.required?(key), class: 'foo'
      end
    end

    # Generates form field markup for resource holding locations
    # @param key [Symbol] the field name
    # @param f [SimpleForm::FormBuilder] the SimpleForm builder Object
    # @return [String] the markup
    def render_holding_location(key, f)
      f.input(key,
              as: :select,
              collection: ControlledVocabulary.for(key).all.sort_by(&:label),
              label_method: :label,
              value_method: :value,
              input_html: { class: 'form-control rights-statement' },
              required: f.object.required?(key))
    end

    # Generates form field markup for languages
    # @param key [Symbol] the field name
    # @param f [SimpleForm::FormBuilder] the SimpleForm builder Object
    # @return [String] the markup
    def render_language(key, f)
      if @language.present?
        f.input(:language,
                label: 'Language',
                collection: reorder_languages(@language, top_languages),
                label_method: :label,
                value_method: :id,
                input_html: {
                  multiple: f.object.multiple?(key)
                },
                required: f.object.required?(key))
      elsif f.object.multiple? key
        f.input(key,
                as: :multi_value,
                input_html: { class: 'form-control' },
                required: f.object.required?(key))
      else
        f.input key, required: f.object.required?(key), class: 'foo'
      end
    end

    # Generates form field markup for the IDs of resource collections
    # @param key [Symbol] the field name
    # @param f [SimpleForm::FormBuilder] the SimpleForm builder Object
    # @return [String] the markup
    def render_member_of_collection_ids(key, f)
      f.input(:member_of_collection_ids,
              collection: @collections.sort_by(&:title),
              label_method: :title,
              value_method: :id,
              input_html: { multiple: f.object.multiple?(key) },
              include_blank: false,
              required: f.object.required?(key))
    end

    # Generates form field markup for the IDs of vocabulary resources
    # @param key [Symbol] the field name
    # @param f [SimpleForm::FormBuilder] the SimpleForm builder Object
    # @return [String] the markup
    def render_member_of_vocabulary_id(key, f)
      f.input(:member_of_vocabulary_id,
              label: 'Vocabulary',
              as: :select,
              collection: @vocabularies,
              label_method: :label,
              value_method: :id,
              input_html: { multiple: f.object.multiple?(key) },
              include_blank: true,
              selected: params[:parent_id] || f.object.member_of_vocabulary_id,
              required: f.object.required?(key))
    end

    # Generates form field markup for navigation dates within visual resources
    # @param _key [Symbol] the field name
    # @param f [SimpleForm::FormBuilder] the SimpleForm builder Object
    # @return [String] the markup
    def render_nav_date(_key, f)
      f.input :nav_date, input_html: { class: 'timepicker' }, required: f.object.required?(:nav_date)
    end

    # Generates form field markup for types of PDFs for document and visual resources
    # @param key [Symbol] the field name
    # @param f [SimpleForm::FormBuilder] the SimpleForm builder Object
    # @return [String] the markup
    def render_pdf_type(key, f)
      f.input(key,
              as: :select,
              collection: ControlledVocabulary.for(key).all,
              label_method: :label,
              value_method: :value,
              include_blank: false,
              input_html: { class: 'form-control rights-statement' },
              required: f.object.required?(key))
    end

    # Generates form field markup for the date at which a resource was received
    # @param _key [Symbol] the field name
    # @param f [SimpleForm::FormBuilder] the SimpleForm builder Object
    # @return [String] the markup
    def render_received_date(_key, f)
      f.input :received_date, input_html: { class: 'timepicker' }, required: f.object.required?(:received_date)
    end

    # Generates form field markup for the rights regarding the access of a given resource
    # @param _key [Symbol] the field name
    # @param f [SimpleForm::FormBuilder] the SimpleForm builder Object
    # @return [String] the markup
    def render_rights_note(_key, f)
      f.input(:rights_note,
              as: :text,
              input_html: {
                class: 'rights-note',
                readonly: !ControlledVocabulary.for(:rights_statement).find(f.object.rights_statement).try(:notable?)
              },
              required: f.object.required?(:rights_note))
    end

    # Generates form field markup for rights statements pertaining to resources
    # @param key [Symbol] the field name
    # @param f [SimpleForm::FormBuilder] the SimpleForm builder Object
    # @return [String] the markup
    def render_rights_statement(key, f)
      f.input(:rights_statement,
              as: :select,
              collection: ControlledVocabulary.for(:rights_statement).all,
              label_method: :label,
              value_method: :value,
              input_html: {
                class: 'form-control rights-statement',
                data: {
                  notable: ControlledVocabulary.for(:rights_statement).all.select(&:notable?).map(&:value)
                }
              },
              required: f.object.required?(key))
    end

    # Generates form field markup for the date at which a resource was shipped
    # @param _key [Symbol] the field name
    # @param f [SimpleForm::FormBuilder] the SimpleForm builder Object
    # @return [String] the markup
    def render_shipped_date(_key, f)
      f.input(:shipped_date,
              input_html: {
                class: 'timepicker'
              },
              required: f.object.required?(:shipped_date))
    end

    # Generates form field markup for bibliographic metadata record ID
    # (For cases where this is imported from other systems)
    # @param _key [Symbol] the field name
    # @param f [SimpleForm::FormBuilder] the SimpleForm builder Object
    # @return [String] the markup
    def render_source_metadata_identifier(_key, f)
      current_id = @change_set.id if @change_set
      source_element = f.input(:source_metadata_identifier,
                               label: 'Source Metadata ID',
                               input_html: {
                                 class: 'mutex detect-duplicates',
                                 data: {
                                   value: current_id,
                                   field: 'source_metadata_identifier_ssim',
                                   model: f.object.model.class.to_s
                                 }
                               })

      refresh_element = f.input(:refresh_remote_metadata, label: 'Refresh metadata from PULFA/Voyager', as: :boolean)
      left_column = content_tag(:div, refresh_element, class: 'col-xs-3')

      visibility_element = f.input(:set_visibility_by_date, label: 'Set visibility by Date Created', as: :boolean)
      center_column = content_tag(:div, visibility_element, class: 'col-xs-3')

      right_column = content_tag(:div, '', class: 'col-xs-6')

      children = left_column + center_column + right_column

      row = content_tag(:div, children, class: 'row')
      source_element + row
    end

    # Generates form field markup for subject classifications for resources
    # @param key [Symbol] the field name
    # @param f [SimpleForm::FormBuilder] the SimpleForm builder Object
    # @return [String] the markup
    def render_subject(key, f)
      if @subject.present?
        f.input(:subject,
                label: 'Subject',
                as: :grouped_select,
                collection: @subject,
                group_method: :terms,
                group_label_method: :label,
                label_method: :label,
                value_method: :id,
                input_html: {
                  multiple: f.object.multiple?(key),
                  data: {
                    live_search: true
                  }
                },
                required: f.object.required?(key))
      elsif f.object.multiple? key
        f.input(key,
                as: :multi_value,
                input_html: { class: 'form-control' },
                required: f.object.required?(key))
      else
        f.input key, required: f.object.required?(key)
      end
    end

    # Generates form field markup for resource titles
    # @param key [Symbol] the field name
    # @param f [SimpleForm::FormBuilder] the SimpleForm builder Object
    # @return [String] the markup
    def render_title(key, f)
      if f.object.respond_to?(:source_metadata_identifier)
        markup = f.input(:title, as: :multi_value, readonly: f.object.source_metadata_identifier.present?, input_html: { class: 'mutex' })
        markup << hidden_field_tag('mutex_field', f.object.title.first || f.object.source_metadata_identifier, required: true)
      elsif f.object.multiple? :title
        markup = f.input(:title, as: :multi_value, input_html: { class: 'form-control' }, required: f.object.required?(key))
      else
        markup = f.input(:title, input_html: { class: 'form-control' }, required: f.object.required?(key))
      end
      markup
    end

    # Generates form field markup for the language of materials within EphemeraFolders
    # @param key [Symbol] the field name
    # @param f [SimpleForm::FormBuilder] the SimpleForm builder Object
    # @return [String] the markup
    # rubocop:disable Style/GuardClause
    def render_top_language(key, f)
      if f.object.language_options.present?
        f.input(:top_language,
                label: 'Top Language',
                hint: 'These will show at the top of the Language select list when editing a folder',
                collection: f.object.language_options,
                label_method: :label,
                value_method: :id,
                input_html: { multiple: f.object.multiple?(key) },
                required: f.object.required?(key))
      end
      # there's no fallback behavior; we only want this form if the ephemera project has a language field
    end
    # rubocop:enable Style/GuardClause
  end
end
