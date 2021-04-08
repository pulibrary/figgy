# frozen_string_literal: true
module OAI::Figgy
  class ValkyrieProviderModel < OAI::Provider::Model
    def self.limit
      10
    end

    require_relative "oai_wrapper"
    def earliest
      query_service.custom_queries.pluck_earliest_updated_at || Time.zone.at(0)
    end

    # Add one second to the current time so that tests will be able to page and
    # won't round down.
    def latest
      Time.current + 1.second
    end

    def sets
      query_service.find_all_of_model(model: Collection).map { |coll| OAI::Set.new(name: coll.title.first, spec: coll.slug.first) }
    end

    def deleted?
      false
    end

    # find is the core method of a model, it returns records from the model
    # bases on the parameters passed in.
    #
    # <tt>selector</tt> can be a singular id, or the symbol :all
    # <tt>options</tt> is a hash of options to be used to constrain the query.
    #
    # Valid options:
    # * :from => earliest timestamp to be included in the results
    # * :until => latest timestamp to be included in the results
    # * :set => the set from which to retrieve the results
    # * :metadata_prefix => type of metadata requested (this may be useful if
    #                       not all records are available in all formats)
    def find(selector, options = {})
      return next_set(options[:resumption_token]) if options[:resumption_token]
      if selector == :all
        find_all(options)
      else
        OAIWrapper.new(query_service.find_by(id: selector))
      end
    end

    class Options < DelegateClass(Hash)
      def marc?
        fetch(:metadata_prefix, "").casecmp("marc21").zero?
      end

      def next_offset
        return 0 unless key?(:last)
        fetch(:last) + ValkyrieProviderModel.limit
      end

      def set
        fetch(:set, nil)
      end

      def from
        fetch(:from, nil)
      end

      def until
        fetch(:until, nil)
      end
    end

    def find_all(options)
      return next_set(options[:resumption_token]) if options[:resumption_token]
      options = Options.new(options)
      result = query_service.custom_queries.paged_all(
        limit: self.class.limit,
        offset: options.next_offset,
        only_models: ScannedResource,
        collection_slug: options.set,
        marc_only: options.marc?,
        from: options.from,
        until_time: options.until,
        requirements: oai_object_requirements,
        exclude_rights: suppress_rights_statements
      ).to_a.compact.map { |r| OAIWrapper.new(r) }
      wrap_results(result, options)
    end

    # State requirements of objects that should show up in the set.
    # @note Values are passed straight to SQL, so ensure they're wrapped in an
    #   array.
    def oai_object_requirements
      {
        state: ["complete"],
        read_groups: [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC]
      }
    end

    def suppress_rights_statements
      [
        RightsStatements.no_copyright_contractual_restrictions
      ]
    end

    def wrap_results(result, options)
      return result if result.length < self.class.limit
      OAI::Provider::PartialResult.new(
        result,
        OAI::Provider::ResumptionToken.new(options.merge(last: options.next_offset))
      )
    end

    def next_set(token_string)
      token = OAI::Provider::ResumptionToken.parse(token_string)
      options = token.to_conditions_hash.merge(last: token.last)
      find_all(options)
    end

    def query_service
      Valkyrie.config.metadata_adapter.query_service
    end
  end
end
