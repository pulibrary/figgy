# frozen_string_literal: true
# Copied from here: https://github.com/rmosolgo/graphql-ruby/issues/3631
class NullQueryWithDataloader < GraphQL::Query::NullContext::NullQuery
  def trace(_key, _data)
    yield
  end

  def multiplex
    nil
  end

  def warden
    nil
  end
end

module GraphqlHelpers
  # Make a GraphQL type instance of the given `type_defn` for `value
  # (Scalars return plain values)
  def make_graphql_object(type_defn, value, context={})
    ctx = GraphQL::Query::Context.new(query: NullQueryWithDataloader.new, values: context, object: nil, schema: FiggySchema)
    type_defn.authorized_new(value, ctx)
  end
end

RSpec.configure do |config|
  config.include GraphqlHelpers
end
