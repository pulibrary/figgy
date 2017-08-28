# frozen_string_literal: true
module PlumImporting
  def import_plum_record(id)
    solr_records = JSON.parse(file_fixture("plum/#{id}.json").read)
    plum_solr.add(solr_records, params: { softCommit: true })
  end

  def plum_solr
    @plum_solr ||= Blacklight.default_index.connection
  end
end

RSpec.configure do |config|
  config.include PlumImporting
end
