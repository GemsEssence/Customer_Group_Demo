# == Schema Information
#
# Table name: customer_groups
#
#  id         :bigint           not null, primary key
#  name       :string
#  is_deafult :boolean          default(FALSE)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require "rails_helper"

RSpec.describe CustomerGroup, type: :model do
  let(:customer_group01) { create(:customer_group, is_deafult: true) }
  let(:customer_group02) { create(:customer_group, is_deafult: true) }

  let(:customer01) { create(:customer, customer_group: customer_group01) }
  let(:customer02) { create(:customer, customer_group: customer_group01, discarded_at: Date.current) }
  let(:customer03) { create(:customer, customer_group: customer_group02) }

  it { expect(described_class.included_modules).to include(Titleize) }
  it { expect(described_class.titleize_fields).to match_array(:name) }

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_least(3).is_at_most(50) }
  end

  describe "associations" do
    it { should have_many(:customers) }
  end

  describe 'callbacks' do
    describe '#validate_delete_customer_group' do
      let!(:default_group) { CustomerGroup.create(name: 'Default Group', is_deafult: true) }
      let!(:regular_group) { CustomerGroup.create(name: 'Regular Group', is_deafult: false) }

      context 'when the group is default' do
        it 'does not allow the group to be deleted' do
          expect { default_group.destroy }.not_to change { CustomerGroup.count }
          expect(default_group.errors[:base]).to include("you can't delete default user group")
        end
      end

      context 'when the group is not default' do
        it 'allows the group to be deleted' do
          expect { regular_group.destroy }.to change { CustomerGroup.count }.by(-1)
          expect(regular_group.destroyed?).to be true
        end
      end
    end
  end

  describe "scope" do
    describe "default" do
      context "when is_deafult is true" do
        it "is expected to fetch records" do
          customer_group_01 = create(:customer_group, is_deafult: false, name: "Cately Yadav")
          customer_group_02 = create(:customer_group, is_deafult: true, name: "Mark Sinha")
          customer_group_03 = create(:customer_group, is_deafult: false, name: "John Roy")
          customer_group_04 = create(:customer_group, is_deafult: true, name: "Laila Ansari")
          customer_group_05 = create(:customer_group, is_deafult: true, name: "Maxwell Sharma")

          result = CustomerGroup.default

          expect(result).to contain_exactly(*customer_group_02, customer_group_04, customer_group_05)
        end
      end

      context "when is_deafult is false" do
        it "is expected to return empty array" do
          customer_group_01 = create(:customer_group, is_deafult: false, name: "Cately Yadav")
          customer_group_02 = create(:customer_group, is_deafult: false, name: "Mark Sinha")

          result = CustomerGroup.default

          expect(result).to be_empty
        end
      end
    end

    describe "by_name" do
      context "when name is matched with perticular person name" do
        it "is expected to fetch records" do
          customer_group_01 = create(:customer_group, is_deafult: false, name: "Cately Yadav")
          customer_group_02 = create(:customer_group, is_deafult: true, name: "Mark Sinha")
          customer_group_03 = create(:customer_group, is_deafult: true, name: "Laila Ansari")

          result = CustomerGroup.by_name("laila")

          expect(result).to contain_exactly(customer_group_03)
        end
      end

      context "when name is matched with group of persons name" do
        it "is expected to fetch records" do
          customer_group_01 = create(:customer_group, is_deafult: false, name: "Serla Armstrong")
          customer_group_02 = create(:customer_group, is_deafult: true, name: "Mark Sinha")
          customer_group_03 = create(:customer_group, is_deafult: true, name: "Sam Jar")
          customer_group_04 = create(:customer_group, is_deafult: false, name: "Rachi Methew")
          customer_group_05 = create(:customer_group, is_deafult: false, name: "Archi Michael")

          result = CustomerGroup.by_name("ar")

          expect(result).to contain_exactly(*customer_group_01, customer_group_02, customer_group_03, customer_group_05)
        end
      end

      context "when name is not matched with any records" do
        it "is expected to return empty array" do
          customer_group_01 = create(:customer_group, is_deafult: false, name: "Cately Yadav")
          customer_group_02 = create(:customer_group, is_deafult: true, name: "Mark Sinha")

          result = CustomerGroup.by_name("john")

          expect(result).to be_empty
        end
      end
    end
  end

  describe "due_amount" do
    let!(:customer01) { create(:customer, due_amount: 100) }
    let!(:customer02) { create(:customer, due_amount: 200) }
    let!(:customer03) { create(:customer, due_amount: 300) }
    let!(:customer_group01) { create(:customer_group, name: "Group 1") }
    let!(:customer_group02) { create(:customer_group, name: "Group 2") }
  
    before do
      customer_group01.customers << customer01
      customer_group01.customers << customer02
      customer_group02.customers << customer03
    end
  
    context "when customers are present" do
      context "when discarded customers are present" do
        context "when total invoice due is greater than 0" do
          it "returns the correct due invoice payment amount" do
            expect(customer_group01.due_amount).to eq(300) 
            expect(customer_group02.due_amount).to eq(300)
          end
        end
      end
  
      context "when discarded customers are not present" do
        it "returns the remaining amount" do
          expect(customer_group01.due_amount).to eq(300)  # 100 + 200
          expect(customer_group02.due_amount).to eq(300)  # 300
        end
      end
    end
  
    context "when customers are not present" do
      let!(:empty_group) { create(:customer_group, name: "Empty Group") }
      it "returns 0" do
        expect(empty_group.due_amount).to be_zero
      end
    end
  end  
end
