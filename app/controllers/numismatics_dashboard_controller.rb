# frozen_string_literal: true
class NumismaticsDashboardController < ApplicationController
  def show
    @issues = Wayfinder.for(NumismaticIssue.new).issues_count
    @accessions = Wayfinder.for(NumismaticAccession.new).accessions_count
    @firms = Wayfinder.for(NumismaticFirm.new).firms_count
    @monograms = Wayfinder.for(NumismaticMonogram.new).monograms_count
    @people = Wayfinder.for(NumismaticPerson.new).people_count
    @places = Wayfinder.for(NumismaticPlace.new).places_count
    @references = Wayfinder.for(NumismaticReference.new).references_count
    authorize! :read, :numismatics
  end
end
