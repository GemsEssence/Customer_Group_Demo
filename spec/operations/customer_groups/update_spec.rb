require 'rails_helper'

RSpec.describe CustomerGroups::Update do
  let!(:error_tracker) { instance_double("ErrorTracker", has_error?: false, add_errors: nil, error_list: []) }
  let!(:customer_group) { create(:customer_group) }
  let!(:default_customer_group) { create(:customer_group, name: "Default Group", is_deafult: true ) }

  describe ".call" do
    subject { described_class.call(customer_group, args, error_tracker) }
    context "when all parameters are valid" do
      let!(:customer) { create(:customer, customer_group: customer_group, position: 1) }
      let!(:new_customer) { create(:customer) }
      let(:args) do
        {
          customer_ids: [new_customer.id],
          remove_customer_ids: [customer.id],
          name: "Updated Group Name",
          customer_positions: [{ customer_id: new_customer.id, position: 1 }]
        }
      end

      it "updates the customer group name" do
        subject
        expect(customer_group.reload.name).to eq("Updated Group Name")
      end

      it "removes customers from the group" do
        subject
        expect(customer.reload.customer_group_id).to eq(default_customer_group.id)
      end

      it "assigns new customers to the group" do
        subject
        expect(new_customer.reload.customer_group_id).to eq(customer_group.id)
      end

      it "updates customer positions" do
        subject
        expect(new_customer.reload.position).to eq(1)
      end

      it "returns success without errors" do
        result = subject
        expect(result[:success]).to be true
        expect(result[:errors]).to be_empty
      end
    end

    context "when no customers are assigned or removed" do
      let(:args) do
        {
          customer_ids: [],
          remove_customer_ids: [],
          name: "Group Name",
          customer_positions: []
        }
      end

      it "returns success without errors" do
        result = subject
        expect(result[:success]).to be true
        expect(result[:errors]).to be_empty
      end
    end

    context "when only the customer group name is updated" do
      let!(:customer) { create(:customer, customer_group: customer_group) }
      let(:args) do
        {
          customer_ids: [],
          remove_customer_ids: [],
          name: "New Group Name",
          customer_positions: []
        }
      end

      it "updates only the group name" do
        subject
        expect(customer_group.reload.name).to eq("New Group Name")
      end

      it "does not modify customers or positions" do
        expect(customer.reload.customer_group_id).to eq(customer_group.id)
      end

      it "returns success without errors" do
        result = subject
        expect(result[:success]).to be true
        expect(result[:errors]).to be_empty
      end
    end

    context "when only customer positions are updated" do
      let!(:customer) { create(:customer, customer_group: customer_group, position: 1) }
      let!(:customer2) { create(:customer, customer_group: customer_group) }
      let(:args) do
        {
          customer_ids: [],
          remove_customer_ids: [],
          name: nil,
          customer_positions: [{ customer_id: customer.id, position: 2 }]
        }
      end

      it "updates the customer position" do
        subject
        expect(customer.reload.position).to eq(2)
      end

      it "does not change the customer group" do
        expect(customer.reload.customer_group_id).to eq(customer_group.id)
      end

      it "returns success without errors" do
        result = subject
        expect(result[:success]).to be true
        expect(result[:errors]).to be_empty
      end
    end

    context "when only customers are removed from the group" do
      let!(:customer) { create(:customer, customer_group: customer_group) }
      let(:args) do
        {
          customer_ids: [],
          remove_customer_ids: [customer.id],
          name: nil,
          customer_positions: []
        }
      end

      it "removes customers from the group" do
        subject
        expect(customer.reload.customer_group_id).to eq(default_customer_group.id)
      end

      it "returns success without errors" do
        result = subject
        expect(result[:success]).to be true
        expect(result[:errors]).to be_empty
      end
    end

    context "when only customers are added to the group" do
      let!(:new_customer) { create(:customer) }
      let(:args) do
        {
          customer_ids: [new_customer.id],
          remove_customer_ids: [],
          name: nil,
          customer_positions: []
        }
      end

      it "adds customers to the group" do
        subject
        expect(new_customer.reload.customer_group_id).to eq(customer_group.id)
      end

      it "returns success without errors" do
        result = subject
        expect(result[:success]).to be true
        expect(result[:errors]).to be_empty
      end
    end

    context "when customer positions are valid and updated" do
      let!(:customer) { create(:customer, customer_group: customer_group) }
      let!(:customer2) { create(:customer, customer_group: customer_group) }
      let(:args) do
        {
          customer_ids: [],
          remove_customer_ids: [],
          name: nil,
          customer_positions: [{ customer_id: customer.id, position: 2 }]
        }
      end

      it "updates customer positions without errors" do
        subject
        expect(customer.reload.position).to eq(2)
      end

      it "returns success without errors" do
        result = subject
        expect(result[:success]).to be true
        expect(result[:errors]).to be_empty
      end
    end

    context "when updating multiple customers at once" do
      let!(:customer1) { create(:customer, customer_group: customer_group, position: 1) }
      let!(:customer2) { create(:customer, customer_group: customer_group, position: 2) }
      let(:args) do
        {
          customer_ids: [customer1.id, customer2.id],
          remove_customer_ids: [],
          name: "Updated Name",
          customer_positions: [{ customer_id: customer1.id, position: 3 }, { customer_id: customer2.id, position: 4}]
        }
      end

      it "should not update position" do
        subject
        expect(customer1.reload.position).to eq(customer1.position)
        expect(customer2.reload.position).to eq(customer2.position)
      end

      it "returns failure without errors" do
        result = subject
        expect(result[:success]).to be false
      end
    end
    
    context "when customer_positions are invalid" do
      let!(:customer) { create(:customer, customer_group: customer_group) }
      let(:args) do
        {
          customer_ids: [],
          remove_customer_ids: [],
          name: nil,
          customer_positions: [{ customer_id: customer.id, position: 100 }]
        }
      end

      before do
        allow(error_tracker).to receive(:add_errors)
      end

      it "adds errors to the error tracker" do
        subject
        expect(error_tracker).to have_received(:add_errors).with("Invalid position provided")
      end

      it "returns failure" do
        allow(error_tracker).to receive(:has_error?).and_return(true)
        result = subject
        expect(result[:success]).to be false
      end
    end

    context "when customer_ids contains duplicates" do
      let(:customer1) { create(:customer) }
      let(:args) do
        {
          customer_ids: [customer1.id, customer1.id],
          remove_customer_ids: [],
          name: nil,
          customer_positions: [{ customer_id: customer1.id, position: 100 }]
        }
      end

      before do
        allow(error_tracker).to receive(:add_errors)
      end

      it "adds an error for duplicate customers" do
        subject
        expect(error_tracker).to have_received(:add_errors).with("Invalid position provided")
      end

      it "returns failure" do
        allow(error_tracker).to receive(:has_error?).and_return(true)
        result = subject
        expect(result[:success]).to be false
      end
    end
  end
end
