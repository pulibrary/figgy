# frozen_string_literal: true
require "rails_helper"

RSpec.describe ArkMismatchReporter do
  let(:logger) { Logger.new(nil) }
  let(:reporter) { described_class.new(output_path: Rails.root.join("tmp", "output.csv"), logger: logger) }

  after do
    FileUtils.rm(Rails.root.join("tmp", "output.csv"), force: true)
  end

  describe ".write" do
    it "writes a csv containing items that have an mms id but an ark that points to findingaids" do
      # create known arks
      shoulder = "99999/fk4"
      blade1 = "123456"
      blade2 = "234567"
      blade3 = "345678"
      stub_request(:post, "https://ezid.cdlib.org/shoulder/ark:/#{shoulder}")
        .to_return(
          { status: 200, body: "success: ark:/#{shoulder}#{blade1}", headers: {} },
          { status: 200, body: "success: ark:/#{shoulder}#{blade2}", headers: {} },
          { status: 200, body: "success: ark:/#{shoulder}#{blade3}", headers: {} }
        )

      # create the resources
      stub_catalog(bib_id: "9946093213506421")
      stub_findingaid(pulfa_id: "AC044_c0003")
      stub_catalog(bib_id: "9985434293506421")
      mismatched_resource = FactoryBot.create_for_repository(:complete_scanned_resource, source_metadata_identifier: "9946093213506421")
      component_resource = FactoryBot.create_for_repository(:complete_scanned_resource, source_metadata_identifier: "AC044_c0003")
      mms_resource = FactoryBot.create_for_repository(:complete_scanned_resource, source_metadata_identifier: "9985434293506421")
      change_set_persister = ChangeSetPersister.default
      change_set_persister.save(change_set: ChangeSet.for(mismatched_resource))
      change_set_persister.save(change_set: ChangeSet.for(component_resource))
      change_set_persister.save(change_set: ChangeSet.for(mms_resource))

      # stub ark targets
      fa_url = "http://findingaids.princeton.edu/collections/RBD1.1/c4768"
      stub_request(:head, "https://n2t.net/ark:/99999/fk4#{blade1}")
        .to_return(status: 200, headers: { "location": fa_url })
      stub_request(:head, "https://n2t.net/ark:/99999/fk4#{blade2}")
        .to_return(status: 200, headers: { "location": "http://www.example.com" })
      stub_request(:head, "https://n2t.net/ark:/99999/fk4#{blade3}")
        .to_return(status: 200, headers: { "location": "http://www.example.com" })

      described_class.write(output_path: Rails.root.join("tmp", "output.csv"))
      csv = CSV.read(Rails.root.join("tmp", "output.csv"), headers: true, header_converters: :symbol)

      expect(csv.length).to eq 1
      resource = csv[0].to_h

      expect(resource[:id]).to eq mismatched_resource.id
      expect(resource[:title]).to eq mismatched_resource.title.first
      expect(resource[:mmsid]).to eq mismatched_resource.source_metadata_identifier.first
      expect(resource[:ark]).to eq mismatched_resource.identifier.first
      expect(resource[:url]).to eq fa_url
    end

    context "when there is no ark" do
      it "skips the resource" do
        stub_catalog(bib_id: "9946093213506421")
        resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "9946093213506421")
        change_set_persister = ChangeSetPersister.default
        change_set_persister.save(change_set: ChangeSet.for(resource))

        expect { reporter.write }.not_to raise_error(NoMethodError)

        csv = CSV.read(Rails.root.join("tmp", "output.csv"), headers: true, header_converters: :symbol)
        expect(csv.length).to eq 0
      end
    end
  end
end
