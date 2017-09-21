# frozen_string_literal: true
require 'rails_helper'

RSpec.describe MessagingClient do
  subject(:messaging_client) { described_class.new('https://localhost:5672', config: { log_level: 'Logger::WARN' }) }

  describe '.new' do
    it 'initializes a new object with an AMQP URL and configuration object' do
      expect(messaging_client.amqp_url).to eq 'https://localhost:5672'
      expect(messaging_client.config).to be_a MessagingClient::Config
      expect(messaging_client.config.log_level).to eq Logger::WARN
    end
  end

  describe '#publish' do
    let(:bunny_class) { class_double("Bunny").as_stubbed_const(transfer_nested_constants: true) }
    let(:bunny) { instance_double(Bunny::Session) }
    let(:channel) { instance_double(Bunny::Channel) }
    let(:exchange) { instance_double(Bunny::Exchange) }

    before do
      allow(Figgy).to receive(:config).and_return('events' => { 'exchange' => { 'plum' => true } })
      allow(channel).to receive(:fanout).and_return(exchange)
      allow(bunny).to receive(:create_channel).and_return(channel)
      allow(bunny).to receive(:start)
      allow(bunny_class).to receive(:new).and_return(bunny)
      allow(exchange).to receive(:publish)
    end

    it 'publishes a message to RabbitMQ' do
      messaging_client.publish(test: :data)
      expect(exchange).to have_received(:publish).with({ test: :data }, persistent: true)
    end

    context 'when an error is encountered interfacing with the messaging client' do
      before do
        allow(Rails.logger).to receive(:warn)
        allow(bunny).to receive(:create_channel).and_raise("some rabbitmq error")
      end

      it 'logs a warning to Rails' do
        messaging_client.publish(test: :data)
        expect(Rails.logger).to have_received(:warn).with("Unable to publish message to https://localhost:5672")
      end
    end
  end
end
