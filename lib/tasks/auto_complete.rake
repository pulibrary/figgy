# frozen_string_literal: true
namespace :figgy do
  namespace :auto_complete do
    desc "Complete all processed complete_when_processed resources."
    task run: :environment do
      AutoCompleter.run
    end
  end
end
