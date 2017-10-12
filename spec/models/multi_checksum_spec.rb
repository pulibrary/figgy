# frozen_string_literal: true
require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe MultiChecksum do
  describe '.for' do
    let(:file) { fixture_file_upload('files/example.tif', 'image/tiff') }
    let(:valk_file) do
      Valkyrie::StorageAdapter::File.new(id: Valkyrie::ID.new('test_id'), io: ::File.open(file, 'rb'))
    end

    it 'returns a correct MultiChecksum' do
      mcs = described_class.for(valk_file)
      expect(mcs.md5).to eq '2a28fb702286782b2cbf2ed9a5041ab1'
      expect(mcs.sha1).to eq '1b95e65efc3aefeac1f347218ab6f193328d70f5'
      expect(mcs.sha256).to eq '547c81b080eb2d7c09e363a670c46960ac15a6821033263867dd59a31376509c'
    end
  end
end
