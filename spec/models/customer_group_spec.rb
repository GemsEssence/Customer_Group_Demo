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
      context "when customer group is default customer" do
        it "is expected to raise an error" do
          customer_group = create(:customer_group, is_default: true)

          expect {
            customer_group.destroy
          }.not_to change { CustomerGroup.all.count }
          expect { (customer_group.destroy).to throw_symbol(:abort) }
          expect(customer_group.errors.full_messages).to contain_exactly(*"you can't delete default user group")
        end
      end

      context "when customer group is not default customer" do
        it "is expected to destroy customer group" do
          customer_group = create(:customer_group, is_default: false)

          expect {
            customer_group.destroy
          }.to change { CustomerGroup.all.count }.from(1).to(0)
          expect(customer_group.errors.full_messages).to be_empty
        end
      end
    end
  end

  describe "unbalance_jar_quantity" do
    let(:product01) { create(:product, returnable: true, discarded_at: nil, agency: agency01) }
    let(:product02) { create(:product, returnable: false, discarded_at: nil, agency: agency01) }
    let(:product03) { create(:product, returnable: true, discarded_at: nil, agency: agency02) }

    let(:jar_transaction_01) { create(:jar_transaction, quantity: 5, balanced_quantity: 4, returnable: true, jar_transaction_type: "delivered", agency: agency01, customer: customer01, product: product01, transaction_date: Date.current) }
    let(:jar_transaction_02) { create(:jar_transaction, quantity: 10, balanced_quantity: 6, returnable: true, jar_transaction_type: "received", agency: agency01, customer: customer01, product: product01, transaction_date: Date.current - 1) }
    let(:jar_transaction_03) { create(:jar_transaction, quantity: 6, balanced_quantity: 6, returnable: true, jar_transaction_type: "delivered", agency: agency01, customer: customer01, product: product01, transaction_date: Date.current - 2) }
    let(:jar_transaction_04) { create(:jar_transaction, quantity: 12, balanced_quantity: 11, returnable: false, jar_transaction_type: "delivered", agency: agency01, customer: customer01, product: product02, transaction_date: Date.current - 3) }
    let(:jar_transaction_05) { create(:jar_transaction, quantity: 22, balanced_quantity: 10, returnable: false, jar_transaction_type: "delivered", agency: agency01, customer: customer02, product: product01, transaction_date: Date.current - 4) }

    let(:jar_transaction_06) { create(:jar_transaction, quantity: 5, balanced_quantity: 4, returnable: true, jar_transaction_type: "delivered", agency: agency02, customer: customer02, product: product03, transaction_date: Date.current - 5) }
    let(:jar_transaction_07) { create(:jar_transaction, quantity: 10, balanced_quantity: 6, returnable: true, jar_transaction_type: "received", agency: agency02, customer: customer02, product: product03, transaction_date: Date.current - 6) }
    let(:jar_transaction_08) { create(:jar_transaction, quantity: 6, balanced_quantity: 3, returnable: false, jar_transaction_type: "delivered", agency: agency02, customer: customer02, product: product03, transaction_date: Date.current - 7) }

    let(:jar_transaction_09) { create(:jar_transaction, quantity: 14, balanced_quantity: 4, returnable: true, jar_transaction_type: "delivered", agency: agency02, customer: customer03, product: product03, transaction_date: Date.current) }
    let(:jar_transaction_10) { create(:jar_transaction, quantity: 12, balanced_quantity: 3, returnable: true, jar_transaction_type: "received", agency: agency02, customer: customer03, product: product03, transaction_date: Date.current) }
    let(:jar_transaction_11) { create(:jar_transaction, quantity: 4, balanced_quantity: 4, returnable: true, jar_transaction_type: "delivered", agency: agency02, customer: customer03, product: product03, transaction_date: Date.current + 1) }

    context "when jar_transaction are present" do
      context "when delivered jar_transaction are present" do
        context "when jar_transaction balanced_quantity != quantity" do
          context "when jar_transaction products are returnable" do
            context "when jar_transaction customers are not discarded" do
              it "is expected to return remaining amount" do
                [jar_transaction_01, jar_transaction_02, jar_transaction_03, jar_transaction_04, jar_transaction_05, jar_transaction_06, jar_transaction_07, jar_transaction_08, jar_transaction_09, jar_transaction_10, jar_transaction_11]

                expect(customer_group01.unbalance_jar_quantity).to eq(1)
                expect(customer_group02.unbalance_jar_quantity).to eq(10)
              end
            end

            context "when jar_transaction customers are discarded" do
              it "is expected to return 0" do
                [jar_transaction_02, jar_transaction_03, jar_transaction_04, jar_transaction_05, jar_transaction_06, jar_transaction_07, jar_transaction_08, jar_transaction_11]

                expect(customer_group01.unbalance_jar_quantity).to be_zero
              end
            end
          end

          context "when jar_transaction products are not returnable" do
            it "is expected to return 0" do
              [jar_transaction_02, jar_transaction_03, jar_transaction_04, jar_transaction_05, jar_transaction_07, jar_transaction_08, jar_transaction_11]

              expect(customer_group01.unbalance_jar_quantity).to be_zero
            end
          end
        end

        context "when jar_transaction balanced_quantity equal to quantity " do
          it "is expected to return 0" do
            [jar_transaction_02, jar_transaction_03, jar_transaction_07, jar_transaction_10, jar_transaction_11]

            expect(customer_group01.unbalance_jar_quantity).to be_zero
          end
        end
      end

      context "when delivered jar_transaction are not present" do
        it "is expected to return 0" do
          [jar_transaction_02, jar_transaction_07, jar_transaction_10]

          expect(customer_group01.unbalance_jar_quantity).to be_zero
        end
      end
    end

    context "when jar_transaction are not present" do
      it "is expected to return 0" do
        expect(customer_group01.unbalance_jar_quantity).to be_zero
      end
    end
  end

  describe "due_amount" do
    context "when customers are present" do
      let(:invoice_01) { create(:invoice, agency: agency01, customer: customer01, amount: 100, additional_charges: 20, paid_amount: 0, discount: 20) }
      let(:invoice_02) { create(:invoice, agency: agency01, customer: customer01, amount: 210, additional_charges: 0, paid_amount: 0, discount: 210) }
      let(:invoice_03) { create(:invoice, agency: agency01, customer: customer01, amount: 99, additional_charges: 1, paid_amount: 4, discount: 88) }
      let(:invoice_04) { create(:invoice, agency: agency01, customer: customer01, amount: 80, additional_charges: 50, paid_amount: 99, discount: 10) }
      let(:invoice_05) { create(:invoice, agency: agency01, customer: customer01, amount: 0, additional_charges: 0, paid_amount: 0, discount: 0) }
      let(:invoice_06) { create(:invoice, agency: agency01, customer: customer01, amount: 0, additional_charges: 20, paid_amount: 20, discount: 0) }

      let(:invoice_07) { create(:invoice, agency: agency01, customer: customer02, amount: 100, additional_charges: 20, paid_amount: 0, discount: 20) }

      let(:invoice_08) { create(:invoice, agency: agency02, customer: customer03, amount: 245, additional_charges: 5, paid_amount: 0, discount: 240) }
      let(:invoice_09) { create(:invoice, agency: agency02, customer: customer03, amount: 130, additional_charges: 0, paid_amount: 70, discount: 50) }
      let(:invoice_10) { create(:invoice, agency: agency02, customer: customer03, amount: 130, additional_charges: 20, paid_amount: 70, discount: 5) }

      context "when discarded customers are present" do
        context "when invoices.amount + invoices.additional_charges - invoices.discount < 0" do
          it "is expected to return 0" do
            [invoice_02, invoice_05, invoice_06]

            expect(customer_group01.due_amount).to be_zero
          end
        end

        context "when invoices.amount + invoices.additional_charges - invoices.discount > 0" do
          it "is expected to return due invoice payment amount" do
            [invoice_01, invoice_02, invoice_03, invoice_04, invoice_05, invoice_06, invoice_07, invoice_08, invoice_09, invoice_10]

            expect(customer_group01.due_amount).to eq(129)
            expect(customer_group02.due_amount).to eq(95)
          end
        end
      end

      context "when discarded customers are not present" do
        it "is expected to return remaining_amount" do
          [invoice_01, invoice_02, invoice_03, invoice_04, invoice_05, invoice_06, invoice_08, invoice_09, invoice_10]

          expect(customer_group01.due_amount).to eq(129)
          expect(customer_group02.due_amount).to eq(95)
        end
      end
    end

    context "when customers are not present" do
      it "is expected to return 0" do
        expect(customer_group01.due_amount).to be_zero
        expect(customer_group02.due_amount).to be_zero
      end
    end
  end

  describe "advance_amount" do
    let(:payment_01) { create(:payment, agency: agency01, customer: customer01, amount: 100, settled_amount: 20, discarded_at: nil) }
    let(:payment_02) { create(:payment, agency: agency01, customer: customer01, amount: 100, settled_amount: 100, discarded_at: nil) }
    let(:payment_03) { create(:payment, agency: agency01, customer: customer01, amount: 100, settled_amount: 50, discarded_at: Date.current) }

    let(:payment_04) { create(:payment, agency: agency01, customer: customer02, amount: 10, settled_amount: 20, discarded_at: nil) }
    let(:payment_05) { create(:payment, agency: agency01, customer: customer02, amount: 105, settled_amount: 20, discarded_at: Date.current) }

    let(:payment_06) { create(:payment, agency: agency02, customer: customer03, amount: 560, settled_amount: 560, discarded_at: nil) }
    let(:payment_07) { create(:payment, agency: agency02, customer: customer03, amount: 10, settled_amount: 20, discarded_at: nil) }

    context "when customers are present" do
      context "when discarded customers are present" do
        context "when amount != settled_amount" do
          context "when discarded payment is not present" do
            it "is expected to return pending amount" do
              [payment_01, payment_02, payment_03, payment_04, payment_05, payment_06, payment_07]

              expect(customer_group01.advance_amount).to eq(80)
              expect(customer_group02.advance_amount).to eq(-10)
            end
          end

          context "when discarded payment is present" do
            it "is expected to return 0" do
              [payment_03, payment_05]

              expect(customer_group01.advance_amount).to be_zero
            end
          end
        end

        context "when amount equal to settled_amount" do
          it "is expected to return 0" do
            [payment_02, payment_06]

            expect(customer_group01.advance_amount).to be_zero
            expect(customer_group02.advance_amount).to be_zero
          end
        end
      end

      context "when discarded customers are not present" do
        it "is expected to return pending amount" do
          [payment_01, payment_02, payment_03, payment_06, payment_07]

          expect(customer_group01.advance_amount).to eq(80)
        end
      end
    end

    context "when customers are not present" do
      it "is expected to return 0" do
        expect(customer_group01.advance_amount).to be_zero
        expect(customer_group02.advance_amount).to be_zero
      end
    end
  end
end
