# frozen_string_literal: true
class NumismaticAccessionWayfinder < BaseWayfinder
  member_relationship :members, model: Coin
  member_relationship :numismatic_references, model: NumismaticReference
end
