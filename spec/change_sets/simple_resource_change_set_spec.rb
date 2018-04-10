# frozen_string_literal: true
require 'rails_helper'

RSpec.describe SimpleResourceChangeSet do
  subject(:change_set) { described_class.new(form_resource) }
  let(:resource_klass) { SimpleResource }
  let(:bookplate) { resource_klass.new(title: 'Test', rights_statement: 'Stuff', visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE, state: 'pending') }
  let(:form_resource) { bookplate }

  it_behaves_like 'a Valhalla::ChangeSet'
end
