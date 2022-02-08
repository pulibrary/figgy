# frozen_string_literal: true
class Pudl3MVWMetsDocument < METSDocument
  def multi_volume?
    true
  end

  def volume_ids
    files.map { |x| x[:path].split("/")[-2] }.uniq
  end

  def label_for_volume(volume_id)
    volume_id.gsub("vol", "")
  end

  def files_for_volume(volume_id)
    files.select { |x| x[:path].include?(volume_id) }
  end

  def structureless?
    true
  end
end
