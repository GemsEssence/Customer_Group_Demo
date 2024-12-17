# == Schema Information
#
# Table name: customers
#
#  id                                :bigint           not null, primary key
#  name                              :string
#  email                             :string
#  mobile_no                         :string
#  address                           :string
#  is_active                         :boolean          default(TRUE)
#  customer_group_id                 :bigint           not null

require "rails_helper"

RSpec.describe Customer, type: :model do
  it { expect(described_class.included_modules).to include(Titleize) }
  it { expect(described_class.titleize_fields).to match_array(:name) }

  describe "constants" do
    it "has AVAILABLE_SHIFTS constant" do
      expect(Customer::AVAILABLE_SHIFTS).to eq([:morning, :afternoon, :evening].freeze)
    end
  end
 
  describe "scope :by_name" do
    let(:customer_group) { create(:customer_group) }
    let(:customer) { create(:customer, customer_group:, name: "Mohan", mobile_no: "1251231231") }
    let(:customer2) { create(:customer, customer_group:, name: "Mohan pandey", mobile_no: "1256789034") }
    let(:customer3) { create(:customer, customer_group:, name: "Ramesh", mobile_no: "0001112220") }
  
    context "when name matched with one record" do
      it "should return customer record" do
        expect(described_class.by_name("MoHAn")).to contain_exactly(customer)
      end
    end
  
    context "when name matched with multiple records" do
      it "should return customer records" do
        expect(described_class.by_name("MohAN")).to contain_exactly(customer, customer2)
      end
    end
  
    context "when name matched partially" do
      it "should return customer records" do
        expect(described_class.by_name("aN")).to contain_exactly(customer, customer2)
      end
    end
  
    context "when name do not matched" do
      it "should return empty array" do
        expect(described_class.by_name("Sumit")).to be_empty
      end
    end
  
    context "when mobile_no matched with one record" do
      it "should return customer record" do
        expect(described_class.by_name("231")).to contain_exactly(customer)
      end
    end
  
    context "when mobile_no matched with multiple records partially or fully" do
      it "should return customer records" do
        expect(described_class.by_name("125")).to contain_exactly(customer, customer2)
      end
    end
  
    context "when mobile_no do not matched" do
      it "should return empty array" do
        expect(described_class.by_name("987")).to be_empty
      end
    end
  end

  describe "#language_preference" do
    it "should return en" do
      customer_group = create(:customer_group)
      customer = create(:customer, customer_group:)

      expect(customer.language_preference).to eq("en")
    end
  end

  describe "#Methods" do
    let(:customer_group) { create(:customer_group) }
    let(:active_customer1) { create(:customer, customer_group: customer_group, is_active: true) }
    let(:active_customer2) { create(:customer, customer_group: customer_group, is_active: true) }
    let(:inactive_customer) { create(:customer, customer_group: customer_group, is_active: false) }
    let(:customer) { create(:customer, customer_group: customer_group) }

    describe "#associated_customers_from_customer_group" do
      it "returns all customers associated with the same customer group" do
        customers = [customer, active_customer1, active_customer2, inactive_customer]
        expect(customer.associated_customers_from_customer_group).to match_array(customers)
      end
    end

    describe "#active_associated_customers_from_customer_group" do
      it "returns only active customers associated with the same customer group" do
        customers = [customer, active_customer1, active_customer2, inactive_customer]
        expect(customer.active_associated_customers_from_customer_group).to contain_exactly(customer, active_customer1, active_customer2)
      end
    end
  end
end
