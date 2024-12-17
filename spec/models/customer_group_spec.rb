# == Schema Information
#
# Table name: customer_groups
#
#  id         :bigint           not null, primary key
#  name       :string
#  is_default :boolean          default(FALSE)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require "rails_helper"

RSpec.describe CustomerGroup, type: :model do
  let(:agency01) { create(:agency) }
  let(:agency02) { create(:agency) }

  let(:customer_group01) { create(:customer_group, is_default: true, agency: agency01) }
  let(:customer_group02) { create(:customer_group, is_default: true, agency: agency02) }

  let(:customer01) { create(:customer, agency: agency01, customer_group: customer_group01) }
  let(:customer02) { create(:customer, agency: agency01, customer_group: customer_group01, discarded_at: Date.current) }
  let(:customer03) { create(:customer, agency: agency02, customer_group: customer_group02) }

  it { expect(described_class.included_modules).to include(Titleize) }
  it { expect(described_class.titleize_fields).to match_array(:name) }

  describe "db_indexes" do
    it { is_expected.to have_db_index(:agency_id) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_least(3).is_at_most(50) }
    it { should validate_uniqueness_of(:name).case_insensitive.scoped_to(:agency_id).with_message("should be uniq, Group already present with same name.") }
  end

  describe "associations" do
    it { should belong_to(:agency) }
    it { should have_many(:customers) }
    it { should have_many(:jar_transactions).through(:customers) }
    it { should have_many(:user_customer_groups).dependent(:destroy) }
  end

  describe "scope" do
    describe "default" do
      context "when is_default is true" do
        it "is expected to fetch records" do
          customer_group_01 = create(:customer_group, is_default: false, name: "Cately Yadav")
          customer_group_02 = create(:customer_group, is_default: true, name: "Mark Sinha")
          customer_group_03 = create(:customer_group, is_default: false, name: "John Roy")
          customer_group_04 = create(:customer_group, is_default: true, name: "Laila Ansari")
          customer_group_05 = create(:customer_group, is_default: true, name: "Maxwell Sharma")

          result = CustomerGroup.default

          expect(result).to contain_exactly(*customer_group_02, customer_group_04, customer_group_05)
        end
      end

      context "when is_default is false" do
        it "is expected to return empty array" do
          customer_group_01 = create(:customer_group, is_default: false, name: "Cately Yadav")
          customer_group_02 = create(:customer_group, is_default: false, name: "Mark Sinha")

          result = CustomerGroup.default

          expect(result).to be_empty
        end
      end
    end

    describe "by_name" do
      context "when name is matched with perticular person name" do
        it "is expected to fetch records" do
          customer_group_01 = create(:customer_group, is_default: false, name: "Cately Yadav")
          customer_group_02 = create(:customer_group, is_default: true, name: "Mark Sinha")
          customer_group_03 = create(:customer_group, is_default: true, name: "Laila Ansari")

          result = CustomerGroup.by_name("laila")

          expect(result).to contain_exactly(customer_group_03)
        end
      end

      context "when name is matched with group of persons name" do
        it "is expected to fetch records" do
          customer_group_01 = create(:customer_group, is_default: false, name: "Serla Armstrong")
          customer_group_02 = create(:customer_group, is_default: true, name: "Mark Sinha")
          customer_group_03 = create(:customer_group, is_default: true, name: "Sam Jar")
          customer_group_04 = create(:customer_group, is_default: false, name: "Rachi Methew")
          customer_group_05 = create(:customer_group, is_default: false, name: "Archi Michael")

          result = CustomerGroup.by_name("ar")

          expect(result).to contain_exactly(*customer_group_01, customer_group_02, customer_group_03, customer_group_05)
        end
      end

      context "when name is not matched with any records" do
        it "is expected to return empty array" do
          customer_group_01 = create(:customer_group, is_default: false, name: "Cately Yadav")
          customer_group_02 = create(:customer_group, is_default: true, name: "Mark Sinha")

          result = CustomerGroup.by_name("john")

          expect(result).to be_empty
        end
      end
    end
  end

  describe "callbacks" do
    describe "before_destroy :validate_delete_customer_group" do
      let!(:customer_group) { create(:customer_group, is_default: is_default) }
  
      context "when customer group is default" do
        let(:is_default) { true }
  
        it "does not destroy the customer group and adds an error" do
          expect {
            customer_group.destroy
          }.not_to change { CustomerGroup.count }
  
          expect { customer_group.destroy }.to throw_symbol(:abort)
          expect(customer_group.errors.full_messages).to contain_exactly("you can't delete default user group")
        end
      end
  
      context "when customer group is not default" do
        let(:is_default) { false }
  
        it "destroys the customer group successfully" do
          expect {
            customer_group.destroy
          }.to change { CustomerGroup.count }.by(-1)
  
          expect(customer_group.errors.full_messages).to be_empty
        end
      end
    end
  end

  describe "due_amount" do
    let(:agency01) { create(:agency) }
    let(:agency02) { create(:agency) }
    let(:customer01) { create(:customer) }
    let(:customer02) { create(:customer) }
    let(:customer03) { create(:customer) }
    let(:customer_group01) { create(:customer_group) }
    let(:customer_group02) { create(:customer_group) }
  
    def create_invoices
      create(:invoice, agency: agency01, customer: customer01, amount: 100, additional_charges: 20, paid_amount: 0, discount: 20) 
      create(:invoice, agency: agency01, customer: customer01, amount: 210, additional_charges: 0, paid_amount: 0, discount: 210) 
      create(:invoice, agency: agency01, customer: customer01, amount: 99, additional_charges: 1, paid_amount: 4, discount: 88)   
      create(:invoice, agency: agency01, customer: customer01, amount: 80, additional_charges: 50, paid_amount: 99, discount: 10) 
      create(:invoice, agency: agency02, customer: customer03, amount: 245, additional_charges: 5, paid_amount: 0, discount: 240) 
      create(:invoice, agency: agency02, customer: customer03, amount: 130, additional_charges: 0, paid_amount: 70, discount: 50) 
      create(:invoice, agency: agency02, customer: customer03, amount: 130, additional_charges: 20, paid_amount: 70, discount: 5) 
    end
  
    context "when customers are present" do
      before { create_invoices }
  
      context "when discarded customers are present" do
        context "when total invoice due is less than or equal to 0" do
          it "returns 0" do
            create(:invoice, agency: agency01, customer: customer01, amount: 210, additional_charges: 0, discount: 210)
            create(:invoice, agency: agency01, customer: customer01, amount: 0, additional_charges: 0, discount: 0)
  
            expect(customer_group01.due_amount).to be_zero
          end
        end
  
        context "when total invoice due is greater than 0" do
          it "returns the correct due invoice payment amount" do
            expect(customer_group01.due_amount).to eq(129)
            expect(customer_group02.due_amount).to eq(95)
          end
        end
      end
  
      context "when discarded customers are not present" do
        it "returns the remaining amount" do
          expect(customer_group01.due_amount).to eq(129)
          expect(customer_group02.due_amount).to eq(95)
        end
      end
    end
  
    context "when customers are not present" do
      it "returns 0" do
        expect(customer_group01.due_amount).to be_zero
        expect(customer_group02.due_amount).to be_zero
      end
    end
  end
end
