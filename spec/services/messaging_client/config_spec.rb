# frozen_string_literal: true
require 'rails_helper'

RSpec.describe MessagingClient::Config do
  describe '#log_level' do
    subject(:config) { described_class.new(log_level: 'Logger::WARN').log_level }
    it 'constantizes log levels' do
      expect(config).to eq Logger::WARN
    end
  end

  describe '#log_file' do
    subject(:config) { described_class.new(log_file: 'STDOUT').log_file }
    it 'constantizes log file paths' do
      expect(config).to eq STDOUT
    end
  end
end
