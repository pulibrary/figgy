# frozen_string_literal: true
class FileSetService
  def self.delete_all_from(resource_id)
    new.delete_all_from(resource_id: resource_id)
  end

  def delete_all_from(resource_id:)
    resource = query_service.find_by(id: resource_id)
    change_set_persister.buffer_into_index do |buffered_change_set_persister|
      Wayfinder.for(resource).file_sets.each do |file_set|
        buffered_change_set_persister.delete(change_set: ChangeSet.for(file_set))
      end
    end
  end

 private

   def change_set_persister
     @change_set_persister ||= ChangeSetPersister.default
   end

   def query_service
     change_set_persister.query_service
   end
end
