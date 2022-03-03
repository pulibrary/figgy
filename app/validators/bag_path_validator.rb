# frozen_string_literal: true
class BagPathValidator < ActiveModel::Validator
  # @param [record] a ChangeSet object
  def validate(record)
    # can't use the activerecord validator on a virtual field
    return if record.bag_path.blank?
    return if Dir.exist?(record.bag_path)
    record.errors.add(:bag_path, "Not a valid bag path")
  end
end
