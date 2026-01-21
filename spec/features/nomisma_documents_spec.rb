require "rails_helper"

RSpec.feature "Nomisma Documents" do
  let(:user) { FactoryBot.create(:admin) }

  before do
    sign_in user
  end

  context "when a user visits the nomisma documents page" do
    it "displays action buttons and a documents table" do
      nomisma_document = NomismaDocument.create!({ state: "complete", rdf: "rdf content" })
      visit nomisma_documents_path
      expect(page).to have_link("VoID RDF", href: "/nomisma/void.rdf")
      expect(page).to have_link("Latest Nomisma RDF", href: "/nomisma/#{nomisma_document.to_param}/princeton-nomisma.rdf")
      expect(page).to have_link("New Nomisma RDF", href: "/nomisma/generate")
      expect(page).to have_css("td[text()='#{nomisma_document.created_at}']")
      expect(page).to have_css("td[text()='complete']")
      expect(page).to have_link("Download", href: "/nomisma/#{nomisma_document.to_param}/princeton-nomisma.rdf")
      expect(page).to have_link("Delete", href: "/nomisma/#{nomisma_document.to_param}")
    end
  end

  context "when a non-authorized user visits the nomisma documents page" do
    let(:user) { FactoryBot.create(:campus_patron) }

    it "does not display delete or generate new buttons" do
      nomisma_document = NomismaDocument.create!({ state: "complete", rdf: "rdf content" })
      visit nomisma_documents_path

      # Hidden content
      expect(page).not_to have_link("Delete", href: "/nomisma/#{nomisma_document.to_param}")
      expect(page).not_to have_link("New Nomisma RDF", href: "/nomisma/generate")

      # Visible content
      expect(page).to have_link("VoID RDF", href: "/nomisma/void.rdf")
      expect(page).to have_link("Latest Nomisma RDF", href: "/nomisma/#{nomisma_document.to_param}/princeton-nomisma.rdf")
      expect(page).to have_css("td[text()='#{nomisma_document.created_at}']")
      expect(page).to have_css("td[text()='complete']")
      expect(page).to have_link("Download", href: "/nomisma/#{nomisma_document.to_param}/princeton-nomisma.rdf")
    end
  end
end
