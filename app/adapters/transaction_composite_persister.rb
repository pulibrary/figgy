# frozen_string_literal: true

#
# Modification of Valkyrie::Persistence::CompositePersister to wrap everything
# up in the first adapter's transaction, so if subsequent persisters fail then
# the transaction is rolled back.
#
# Useful for indexing in the IndexingAdapter.
#
class TransactionCompositePersister < Valkyrie::Persistence::CompositePersister
  def save(resource:, external_resource: false)
    wrap_with_transaction do
      super
    end
  end

  def delete(resource:)
    wrap_with_transaction do
      super
    end
  end

  def wrap_with_transaction
    return yield unless persisters.first.try(:connection).respond_to?(:transaction)
    persisters.first.connection.transaction(savepoint: true) do
      yield
    end
  end
end
