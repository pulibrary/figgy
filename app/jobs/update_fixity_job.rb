# frozen_string_literal: true
class UpdateFixityJob < ApplicationJob
  def perform(status:, resource_id:, child_id:); end
end
