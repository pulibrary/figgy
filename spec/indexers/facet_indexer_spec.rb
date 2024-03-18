# frozen_string_literal: true
require "rails_helper"

RSpec.describe FacetIndexer do
  describe ".to_solr" do
    context "when the resource has imported catalog metadata" do
      it "indexes relevant facets" do
        stub_catalog(bib_id: "991234563506421")
        scanned_resource = FactoryBot.create(:pending_scanned_resource, source_metadata_identifier: "991234563506421", import_metadata: true)
        solr_record = Blacklight.default_index.connection.get("select", params: { qt: "document", q: "*:*" })["response"]["docs"][0]

        expect(solr_record["display_subject_ssim"]).to eq scanned_resource.imported_metadata.first.subject
        expect(solr_record["display_language_ssim"]).to eq ["English"]
        expect(solr_record["pub_date_start_itsi"]).to eq 1982
      end

      it "reindexes relevant facets" do
        stub_catalog(bib_id: "991234563506421")
        scanned_resource = FactoryBot.create(:pending_scanned_resource, source_metadata_identifier: "991234563506421", import_metadata: true)
        output = described_class.new(resource: scanned_resource).to_solr

        expect(output[:display_subject_ssim]).to eq scanned_resource.imported_metadata.first.subject
        expect(output[:display_language_ssim]).to eq ["English"]
        expect(output[:pub_date_start_itsi]).to eq 1982
      end

      it "parses the first year from a date range" do
        # 1699-01-01T00:00:00Z/1700-12-31T23:59:59Z
        bib_id = "9930134813506421"
        stub_catalog(bib_id: bib_id)
        scanned_resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: bib_id, import_metadata: true)

        output = described_class.new(resource: scanned_resource).to_solr
        expect(output[:pub_date_start_itsi]).to eq 1699
      end

      it "handles an empty date created" do
        bib_id = "99001000179035064213506421"
        stub_catalog(bib_id: bib_id)
        scanned_resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: bib_id, import_metadata: true)

        output = described_class.new(resource: scanned_resource).to_solr
        expect(output[:pub_date_start_itsi]).to eq nil
      end

      it "handles a non-date string" do
        bib_id = "99100017913506421"
        stub_catalog(bib_id: bib_id)
        scanned_resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: bib_id, import_metadata: true)

        output = described_class.new(resource: scanned_resource).to_solr
        expect(output[:pub_date_start_itsi]).to eq nil
      end

      it "handles a non string" do
        # gives TypeError
        bib_id = "99100017923506421"
        stub_catalog(bib_id: bib_id)
        scanned_resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: bib_id, import_metadata: true)

        output = described_class.new(resource: scanned_resource).to_solr
        expect(output[:pub_date_start_itsi]).to eq nil
      end

      it "handles a bad date" do
        # gives ArgumentError
        bib_id = "991234567893506421"
        stub_catalog(bib_id: bib_id)
        scanned_resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: bib_id, import_metadata: true)

        output = described_class.new(resource: scanned_resource).to_solr
        expect(output[:pub_date_start_itsi]).to eq nil
      end
    end

    context "when the resource has imported pulfa metadata" do
      it "parses the first year from a date range" do
        # 1941-01-01T00:00:00Z/1985-12-31T23:59:59Z
        pulfa_id = "C0652_c0377"
        stub_findingaid(pulfa_id: pulfa_id)
        scanned_resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: pulfa_id, import_metadata: true)

        output = described_class.new(resource: scanned_resource).to_solr
        expect(output[:pub_date_start_itsi]).to eq 1941
      end
    end

    context "when the resource has only local metadata" do
      let(:vocabulary) { FactoryBot.create_for_repository(:ephemera_vocabulary, label: "Large vocabulary") }
      let(:category) { FactoryBot.create_for_repository(:ephemera_vocabulary, label: "Egg Creatures", member_of_vocabulary_id: [vocabulary.id]) }
      let(:language) { FactoryBot.create_for_repository(:ephemera_term, label: "English", member_of_vocabulary_id: [vocabulary.id]) }
      let(:subject_terms) do
        [FactoryBot.create_for_repository(:ephemera_term, label: "Birdo", member_of_vocabulary_id: [category.id]),
         FactoryBot.create_for_repository(:ephemera_term, label: "Yoshi", member_of_vocabulary_id: [category.id])]
      end
      it "indexes subject, language" do
        folder = FactoryBot.create_for_repository(:ephemera_folder, subject: subject_terms, language: language)
        output = described_class.new(resource: folder).to_solr

        expect(output[:display_subject_ssim]).to contain_exactly("Birdo", "Yoshi", "Egg Creatures")
        expect(output[:display_language_ssim]).to contain_exactly("English")
      end
    end

    context "when the resource has structure" do
      it "indexes its presence" do
        file_set = FactoryBot.create_for_repository(:file_set)
        scanned_resource = FactoryBot.create_for_repository(
          :scanned_resource,
          member_ids: file_set.id,
          thumbnail_id: file_set.id,
          logical_structure: [
            { label: "testing", nodes: [{ label: "Chapter 1", nodes: [{ proxy: file_set.id }] }] }
          ]
        )

        output = described_class.new(resource: scanned_resource).to_solr
        expect(output[:has_structure_bsi]).to be true
      end
    end

    context "when the resource does not have structure" do
      it "indexes its absence" do
        file_set = FactoryBot.create_for_repository(:file_set)
        scanned_resource = FactoryBot.create_for_repository(
          :scanned_resource,
          member_ids: file_set.id,
          thumbnail_id: file_set.id
        )

        output = described_class.new(resource: scanned_resource).to_solr
        expect(output[:has_structure_bsi]).to be false
      end
    end

    context "when the resource has a video file" do
      it "indexes a Video file type" do
        file_set = FactoryBot.create_for_repository(:video_file_set)
        scanned_resource = FactoryBot.create_for_repository(
          :scanned_resource,
          member_ids: file_set.id
        )

        output = described_class.new(resource: scanned_resource).to_solr
        expect(output[:file_type_ssim]).to contain_exactly("Video")
      end
    end

    context "when the resource has a video file and an image file" do
      it "indexes only indexes a Video file type" do
        video_file_set = FactoryBot.create_for_repository(:video_file_set)
        image_file_set = FactoryBot.create_for_repository(:original_image_file_set)
        scanned_resource = FactoryBot.create_for_repository(
          :scanned_resource,
          member_ids: [video_file_set.id, image_file_set.id]
        )

        output = described_class.new(resource: scanned_resource).to_solr
        expect(output[:file_type_ssim]).to contain_exactly("Video")
      end
    end

    context "when the resource has an audio file" do
      it "indexes an Audio file type" do
        file_set = FactoryBot.create_for_repository(:audio_file_set)
        scanned_resource = FactoryBot.create_for_repository(
          :scanned_resource,
          member_ids: file_set.id
        )

        output = described_class.new(resource: scanned_resource).to_solr
        expect(output[:file_type_ssim]).to contain_exactly("Audio")
      end
    end

    context "when a MapSet resource has raster mosaic files" do
      it "indexes a Raster Mosaic file type" do
        scanned_map = FactoryBot.create_for_repository(:scanned_map_with_multiple_clipped_raster_children)
        map_set = FactoryBot.create_for_repository(:scanned_map, member_ids: [scanned_map.id], id: "331d70a5-4bd9-4a65-80e4-763c8f6b34fd")

        output = described_class.new(resource: map_set).to_solr
        expect(output[:file_type_ssim]).to contain_exactly("Raster Mosaic")
      end
    end

    context "when a Raster resource has raster mosaic files" do
      it "indexes a Raster Mosaic file type" do
        raster_set = FactoryBot.create_for_repository(:raster_set_with_files)

        output = described_class.new(resource: raster_set).to_solr
        expect(output[:file_type_ssim]).to contain_exactly("Raster Mosaic")
      end
    end
  end
end
