# frozen_string_literal: true
# This resource represents a single catalog dump and tracks whether it has been
#   processed to refresh metadata from voyager
# We need to do this because catalog provides an ongoing list of dump events,
#   without any filtering and with occasional changes in frequency.
#   Each time we update from voyager we sift through the
#   dumps to process the ones that haven't been done yet.
# @see VoyagerUpdater::EventStream
# @see rake figgy:update_bib_ids
class ProcessedEvent < Valkyrie::Resource
  attribute :event_id
end
