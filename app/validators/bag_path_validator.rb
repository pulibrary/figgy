# frozen_string_literal: true
class BagPathValidator < ActiveModel::Validator
  # @param [record] a ChangeSet object
  def validate(record)
    # can't use the activerecord validator on a virtual field
    return if record.bag_path.present?
    record.errors.add(:bag_path, "No value found")
  end
end
