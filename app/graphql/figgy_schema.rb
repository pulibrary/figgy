# frozen_string_literal: true

class FiggySchema < GraphQL::Schema
  mutation(Types::MutationType)
  query(Types::QueryType)
end
