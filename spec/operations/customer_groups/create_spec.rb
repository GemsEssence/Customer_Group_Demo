require 'rails_helper'

RSpec.describe CustomerGroups::Create do
  describe '.call' do
    let!(:error_tracker) { instance_double('ErrorTracker', add_errors: nil, error_list: [], has_error?: false) }
    let!(:customer_group) { create(:customer_group, is_deafult: true) }
    
    let!(:customer01) { create(:customer, customer_group: customer_group) }
    let!(:customer02) { create(:customer, customer_group: customer_group) }
    let!(:customer03) { create(:customer, customer_group: customer_group) }

    let!(:customer_ids) { [customer01.id, customer02.id, customer03.id] }
    let!(:customers) { [customer01, customer02, customer03] }

    before do
      allow(::ErrorTracker).to receive(:new).and_return(error_tracker)
      allow(customer_group).to receive(:save).and_return(true)
      allow(Customer).to receive(:where).and_return(customers)
      allow(Customer).to receive(:pluck).and_return([nil, nil, nil])
      allow(CustomerGroups::ResetCustomerPosition).to receive(:call).and_return(true)
    end

    context 'when customer group creation and assignment succeeds' do
      it 'returns a success result' do
        result = described_class.call(customer_group, customer_ids, error_tracker)

        expect(result[:success]).to eq(true)
        expect(result[:errors]).to eq([])
        expect(result[:result]).to eq(customer_group)
      end

      it 'calls reset customer positions' do
        described_class.call(customer_group, customer_ids, error_tracker)

        expect(CustomerGroups::ResetCustomerPosition).to have_received(:call).twice
      end
    end

    context 'when customer group fails to save' do
      before do
        allow_any_instance_of(CustomerGroup).to receive(:save).and_return(false)
        allow_any_instance_of(CustomerGroup).to receive_message_chain(:errors, :full_messages).and_return(['Name can\'t be blank'])
        allow(error_tracker).to receive(:has_error?).and_return(true)
      end

      it 'adds errors to the error tracker and returns failure' do
        result = described_class.call(customer_group, customer_ids, error_tracker)
        expect(result[:success]).to eq(false)
        expect(result[:result]).to be_nil
      end
    end

    context 'when updating customers fails' do
      before do
        allow(customers.first).to receive(:update).and_wrap_original do |method, *args|
          method.call(*args)
        end
        allow(error_tracker).to receive(:has_error?).and_return(true)
      end

      it 'adds errors to the error tracker and returns failure' do
        result = described_class.call(customer_group, customer_ids, error_tracker)

        expect(result[:success]).to eq(false)
        expect(result[:result]).to be_nil
      end
    end

    context 'when reset customer position raises an exception' do
      before do
        allow(CustomerGroups::ResetCustomerPosition).to receive(:call).and_raise(StandardError, 'Reset failed')
        allow(error_tracker).to receive(:has_error?).and_return(true)
      end

      it 'captures the error and returns failure' do
        expect {
          described_class.call(customer_group, customer_ids, error_tracker)
        }.to raise_error(StandardError, 'Reset failed')
      end
    end

    context 'when there are no customers to assign' do
      it 'still succeeds without errors' do
        result = described_class.call(customer_group, [], error_tracker)

        expect(result[:success]).to eq(true)
        expect(result[:errors]).to eq([])
        expect(result[:result]).to eq(customer_group)
      end
    end
  end
end
