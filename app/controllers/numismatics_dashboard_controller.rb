# frozen_string_literal: true

class NumismaticsDashboardController < ApplicationController
  def show
    @issues = Wayfinder.for(Numismatics::Issue.new).issues_count
    @accessions = Wayfinder.for(Numismatics::Accession.new).accessions_count
    @firms = Wayfinder.for(Numismatics::Firm.new).firms_count
    @monograms = Wayfinder.for(Numismatics::Monogram.new).monograms_count
    @people = Wayfinder.for(Numismatics::Person.new).people_count
    @places = Wayfinder.for(Numismatics::Place.new).places_count
    @references = Wayfinder.for(Numismatics::Reference.new).references_count
    authorize! :read, :numismatics
  end
end
