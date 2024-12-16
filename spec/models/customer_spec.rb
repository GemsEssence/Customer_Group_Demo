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
  it { expect(described_class.included_modules).to include(Discard::Model) }
  it { expect(described_class.included_modules).to include(Titleize) }
  it { expect(described_class.included_modules).to include(MobileInvitable) }
  it { expect(described_class.titleize_fields).to match_array(:name) }

  describe "callbacks" do
    it "titleizes name before validation" do
      agency = build(:agency, name: "test agency")
      expect {
        agency.valid?
      }.to change { agency.name }.from("test agency").to("Test Agency")
    end
  end

  describe "constants" do
    it "has AVAILABLE_SHIFTS constant" do
      expect(Customer::AVAILABLE_SHIFTS).to eq([:morning, :afternoon, :evening].freeze)
    end
  end

  describe "acts_as_list" do
    let(:user) { create(:user) }
    let(:agency) { create(:agency) }
    let(:agency_user) { create(:agency_user, user:, agency:, owner_user: user) }

    let(:customer_group) { create(:customer_group, agency:) }
    let(:customer_group2) { create(:customer_group, agency:) }
    let(:customer_group3) { create(:customer_group, agency:) }

    it "should scope positions by customer_group_id and discarded_at" do
      customer1 = create(:customer, customer_group: customer_group2, agency: agency)
      customer2 = create(:customer, customer_group: customer_group2, agency: agency, discarded_at: Date.current)
      customer3 = create(:customer, customer_group: customer_group2, agency: agency, discarded_at: Date.current)

      customer6 = create(:customer, customer_group: customer_group3, agency: agency)
      customer7 = create(:customer, customer_group: customer_group3, discarded_at: Date.current, agency: agency)
      customer8 = create(:customer, customer_group: customer_group3, agency: agency)

      customer4 = create(:customer, customer_group: customer_group2, agency: agency)
      customer5 = create(:customer, customer_group: customer_group2, agency: agency)

      customer9 = create(:customer, customer_group: customer_group, agency: agency, discarded_at: Date.current)
      customer10 = create(:customer, customer_group: customer_group, agency: agency)
      customer11 = create(:customer, customer_group: customer_group, agency: agency)

      expect(customer1.position).to eq(1)
      expect(customer2.position).to eq(2)
      expect(customer3.position).to eq(2)
      expect(customer4.position).to eq(2)
      expect(customer5.position).to eq(3)

      expect(customer6.position).to eq(1)
      expect(customer7.position).to eq(2)
      expect(customer8.position).to eq(2)

      expect(customer9.position).to eq(1)
      expect(customer10.position).to eq(1)
      expect(customer11.position).to eq(2)
    end
  end

  describe "enum" do
    it { should define_enum_for(:invoice_preference).with_values(monthly: 0, bimonthly: 1).backed_by_column_of_type(:integer).with_prefix(true) }
  end

  describe "associations" do
    it { should belong_to(:agency) }
    it { should belong_to(:customer_group) }
    it { should belong_to(:invited_by).class_name("User").with_foreign_key(:invited_by_id).optional(true) }
    it { should have_one(:customer_delivery_preference).dependent(:destroy) }
    it { should have_one(:customer_payment_preference).dependent(:destroy) }
    it { should have_many(:schedule_delivery_cancellations).dependent(:destroy) }
    it { should have_many(:customer_agency_customers).dependent(:destroy) }
    it { should have_many(:agency_customers).through(:customer_agency_customers) }
    it { should have_many(:jar_transactions).dependent(:destroy) }
    it { should have_many(:jar_transaction_summaries).dependent(:destroy) }
    it { should have_many(:customer_products).dependent(:destroy) }
    it { should have_many(:customer_qr_codes).dependent(:destroy) }
    it { should have_many(:payments).dependent(:destroy) }
    it { should have_many(:invoices).dependent(:destroy) }
    it { should have_many(:sms_records).dependent(:destroy) }
    it { should have_many(:event_customers).dependent(:destroy) }
    it { should have_many(:balance_customer_products).dependent(:destroy) }
    it { should have_one_attached(:profile_image) }
  end

  describe "validations" do
    let(:user) { create(:user) }
    let(:agency) { create(:agency) }
    let(:agency_user) { create(:agency_user, user:, agency:, owner_user: user) }
    let(:customer_group) { create(:customer_group, agency:) }
    let(:customer) { create(:customer, mobile_no: "1212121212", name: "Ram", agency: agency, customer_group: customer_group) }

    subject { customer }

    it { should validate_presence_of(:mobile_no) }
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_least(3).is_at_most(50) }

    it "is expected to have error message when mobile_no is not unique with same agency" do
      [customer]
      customer2 = build(:customer, mobile_no: "1212121212", name: "Radha", agency: agency, customer_group: customer_group)

      expect(customer.valid?).to be true
      expect(customer2.valid?).to be false
      expect(customer2.errors.full_messages).to contain_exactly(*"Mobile no should be uniq. Customer already exists with same mobile no.")
    end

    it "is expected to have error message when name is not unique with same agency" do
      [customer]
      customer2 = build(:customer, mobile_no: "1234512907", name: "Ram", agency: agency, customer_group: customer_group)

      expect(customer.valid?).to be true
      expect(customer2.valid?).to be false
      expect(customer2.errors.full_messages).to contain_exactly(*"Name should be uniq. Please enter another name to identify customer.")
    end
  end

  describe "nested_attributes" do
    it { should accept_nested_attributes_for(:customer_payment_preference) }
    it { should accept_nested_attributes_for(:customer_delivery_preference) }
    it { should accept_nested_attributes_for(:jar_transactions) }
    it { should accept_nested_attributes_for(:customer_products).allow_destroy(true) }
  end

  describe "validate_assign_customer" do
    let(:agency) { create(:agency) }
    let(:agency2) { create(:agency) }
    let(:agency3) { create(:agency) }
    let(:customer_group) { create(:customer_group, agency:) }
    let(:customer_group2) { create(:customer_group, agency: agency2) }
    let(:customer_group3) { create(:customer_group, agency: agency3) }

    context "when a new record is created" do
      context "when agency is same" do
        it "should pass the validation" do
          customer = build(:customer, mobile_no: "1212121212", name: "Ram", agency:, customer_group:)

          expect(customer.save).to be true
          expect(customer.errors.full_messages).to be_empty
        end
      end

      context "when agency is different" do
        it "should add error" do
          customer = build(:customer, mobile_no: "3423425678", name: "Shyam", agency:, customer_group: customer_group2)

          expect(customer.save).to be false
          expect(customer.errors.full_messages).to contain_exactly(*"Customer doesn't belongs to agency")
          expect { (customer.save).to throw_symbol(:abort) }
        end
      end

      context "when customer do not have customer_group" do
        it "should add the error" do
          customer = build(:customer, mobile_no: "1212121212", name: "Ram", agency:, customer_group: nil)

          expect(customer.save).to be false
          expect(customer.errors.full_messages).to contain_exactly(*"Customer group must exist")
          expect { (customer.save).to throw_symbol(:abort) }
        end
      end
    end

    context "when an existing record is updated" do
      let(:customer) { create(:customer, agency:, customer_group:) }
      context "when agency is same" do
        it "should pass the validation" do
          [customer]
          expect(customer.update(agency: agency3, customer_group: customer_group3)).to be true
          expect(customer.errors.full_messages).to be_empty
        end
      end

      context "when agency is different" do
        it "should add error" do
          [customer]
          expect(customer.update(agency: agency3, customer_group: customer_group2)).to be false
          expect(customer.errors.full_messages).to contain_exactly(*"Customer doesn't belongs to agency")
          expect { customer.update(agency: agency3, customer_group: customer_group2).to throw_symbol(:abort) }
        end
      end

      context "when setting customer_group to nil" do
        it "should add the error" do
          [customer]
          expect(customer.update(customer_group: nil)).to be false
          expect(customer.errors.full_messages).to contain_exactly(*"Customer group must exist")
          expect { customer.update(customer_group: nil).to throw_symbol(:abort) }
        end
      end
    end
  end

  describe "scope :by_name" do
    let(:agency) { create(:agency) }
    let(:customer_group) { create(:customer_group, agency:) }
    let(:customer) { create(:customer, agency:, customer_group:, name: "Mohan", mobile_no: "1251231231") }
    let(:customer2) { create(:customer, agency:, customer_group:, name: "Mohan pandey", mobile_no: "1256789034") }
    let(:customer3) { create(:customer, agency:, customer_group:, name: "Ramesh", mobile_no: "0001112220") }

    context "when name matched with one record" do
      it "should return customer record" do
        [customer, customer3]
        expect(described_class.by_name("MoHAn")).to contain_exactly(*customer)
      end
    end

    context "when name matched with multiple record" do
      it "should return customer record" do
        [customer, customer2]
        expect(described_class.by_name("MohAN")).to contain_exactly(*customer, customer2)
      end
    end

    context "when name matched partially" do
      it "should return customer record" do
        [customer, customer2]
        expect(described_class.by_name("aN")).to contain_exactly(*customer, customer2)
      end
    end

    context "when name do not matched" do
      it "should return empty array" do
        [customer, customer2]
        expect(described_class.by_name("Sumit")).to be_empty
      end
    end

    context "when mobile_no matched with one record" do
      it "should return customer record" do
        [customer, customer2]
        expect(described_class.by_name("231")).to contain_exactly(*customer)
      end
    end

    context "when mobile_no matched with multiple record partially or fully" do
      it "should return customer record" do
        [customer, customer2]
        expect(described_class.by_name("125")).to contain_exactly(*customer, customer2)
      end
    end

    context "when mobile_no do not matched" do
      it "should return empty array" do
        [customer, customer2]
        expect(described_class.by_name("987")).to be_empty
      end
    end
  end

  describe "#unbalance_jar_quantity" do
    let(:user) { create(:user) }
    let(:user2) { create(:user) }

    let(:agency2) { create(:agency) }
    let(:agency) { create(:agency) }

    let(:agency_user) { create(:agency_user, user:, agency:, owner_user: user) }
    let(:agency_user2) { create(:agency_user, user: user2, agency: agency2, owner_user: user2) }

    let(:product) { create(:product, agency:, owner_user: user) }
    let(:non_returnable_product) { create(:product, agency:, owner_user: user, returnable: false) }
    let(:product2) { create(:product, agency:, owner_user: user) }
    let(:product3) { create(:product, agency: agency2, owner_user: user2) }

    let(:customer) { create(:customer, agency:) }
    let(:customer2) { create(:customer, agency:) }
    let(:customer3) { create(:customer, agency: agency2) }

    let(:customer_product) { create(:customer_product, customer:, product:) }
    let(:non_returnable_customer_product) { create(:customer_product, customer:, product: non_returnable_product) }
    let(:customer_product2) { create(:customer_product, customer:, product: product2) }
    let(:customer_product3) { create(:customer_product, customer: customer3, product:) }

    let(:jar_transaction1) { create(:jar_transaction, jar_transaction_type: 0, balanced_quantity: 60, quantity: 100, product: non_returnable_product, customer: customer, returnable: false) }

    let(:jar_transaction2) { create(:jar_transaction, jar_transaction_type: 0, balanced_quantity: 100, quantity: 100, product: product, customer: customer, returnable: true) }

    let(:jar_transaction3) { create(:jar_transaction, jar_transaction_type: 0, balanced_quantity: 100, quantity: 100, product: product, customer: customer, returnable: false) }

    let(:jar_transaction4) { create(:jar_transaction, jar_transaction_type: 0, balanced_quantity: 80, quantity: 100, product: product, customer: customer, returnable: true) }

    let(:jar_transaction5) { create(:jar_transaction, jar_transaction_type: 0, balanced_quantity: 80, quantity: 200, product: product, customer: customer, returnable: true) }

    let(:jar_transaction6) { create(:jar_transaction, jar_transaction_type: 0, balanced_quantity: 80, quantity: 200, product: product, customer: customer2, returnable: true) }

    let(:jar_transaction7) { create(:jar_transaction, jar_transaction_type: 1, balanced_quantity: 80, quantity: 200, product: product, customer: customer, returnable: true) }

    let(:jar_transaction8) { create(:jar_transaction, jar_transaction_type: 0, balanced_quantity: 100, quantity: 120, product: product2, customer: customer, returnable: true) }

    let(:jar_transaction9) { create(:jar_transaction, jar_transaction_type: 0, balanced_quantity: 80, quantity: 200, product: product3, customer: customer3, returnable: true) }

    it "should exclude non-returnable products and balance_txns" do
      [jar_transaction1, jar_transaction2, jar_transaction3]
      expect(customer.unbalance_jar_quantity).to eq(0)
    end

    it "should return the unbalanced amount" do
      [jar_transaction2, jar_transaction4, jar_transaction5]
      expect(customer.unbalance_jar_quantity).to eq(140)
    end

    it "should exclude the recevied jar_txn_type" do
      [jar_transaction4, jar_transaction5, jar_transaction7]
      expect(customer.unbalance_jar_quantity).to eq(140)
    end

    it "should execlude others customers txn" do
      [jar_transaction5, jar_transaction6]
      expect(customer.unbalance_jar_quantity).to eq(120)
    end

    it "should include all product txn of the customer" do
      [jar_transaction5, jar_transaction8]
      expect(customer.unbalance_jar_quantity).to eq(140)
    end

    it "should execlude other agencies customer txn" do
      [jar_transaction5, jar_transaction9]
      expect(customer.unbalance_jar_quantity).to eq(120)
    end
  end

  describe "#due_amount" do
    let(:agency) { create(:agency) }
    let(:agency2) { create(:agency) }

    let(:customer_group) { create(:customer_group, agency:) }
    let(:customer_group2) { create(:customer_group, agency: agency2) }

    let(:customer) { create(:customer, agency:, customer_group:) }
    let(:another_customer) { create(:customer, agency:, customer_group:) }
    let(:customer2) { create(:customer, agency: agency2, customer_group: customer_group2) }

    let(:invoice) { create(:invoice, agency:, customer:, amount: 520, additional_charges: 20, paid_amount: 210, discount: 10) }

    let(:invoice1) { create(:invoice, agency:, customer:, amount: 500, additional_charges: 20, paid_amount: 210, discount: 10) }

    let(:invoice2) { create(:invoice, agency:, customer:, amount: 500, additional_charges: 20, paid_amount: 310, discount: 210) }

    let(:invoice3) { create(:invoice, agency:, customer: another_customer, amount: 500, additional_charges: 20, paid_amount: 210, discount: 10) }

    let(:invoice4) { create(:invoice, agency: agency2, customer: customer2, amount: 500, additional_charges: 20, paid_amount: 210, discount: 10) }

    let(:invoice5) { create(:invoice, agency:, customer:, amount: 520, additional_charges: 20, paid_amount: 320, discount: 220) }

    let(:invoice6) { create(:invoice, agency:, customer:, amount: 520, additional_charges: 20, paid_amount: 320, discount: 220, total_gst_amount: 30) }

    it "should exclude paid_invoices" do
      [invoice, invoice1, invoice2]
      expect(customer.due_amount).to eq(620)
    end

    it "should exclude invoices of other customers" do
      [invoice1, invoice3]
      expect(customer.due_amount).to eq(300)
    end

    it "should exclude other agency's customer invoices" do
      [invoice1, invoice4]
      expect(customer.due_amount).to eq(300)
    end

    it "should return 0 when there is no due amount" do
      [invoice2, invoice5]
      expect(customer.due_amount).to eq(0)
    end

    it "should return due amount when only one invoice present" do
      [invoice]
      expect(customer.due_amount).to eq(320)
    end

    it "should return due_amount with gst_amount" do
      customer.update(gst_enabled: true)
      [invoice, invoice2, invoice6]
      invoice.update(total_gst_amount: 40)
      invoice2.update(total_gst_amount: 100)
      expect(customer.due_amount).to eq(490)
    end

  end

  describe "#past_due_amount" do
    let(:agency) { create(:agency) }
    let(:agency2) { create(:agency) }

    let(:customer_group) { create(:customer_group, agency:) }
    let(:customer_group2) { create(:customer_group, agency: agency2) }

    let(:customer) { create(:customer, agency:, customer_group:) }
    let(:another_customer) { create(:customer, agency:, customer_group:) }
    let(:customer2) { create(:customer, agency: agency2, customer_group: customer_group2) }

    let(:invoice) { create(:invoice, agency:, customer:, amount: 210, additional_charges: 20, discount: 20, paid_amount: 100, start_on: Date.current - 3) }

    let(:invoice2) { create(:invoice, agency:, customer:, amount: 680, additional_charges: 120, discount: 50, paid_amount: 750, start_on: Date.current - 4) }

    let(:invoice3) { create(:invoice, agency:, customer:, amount: 140, additional_charges: 60, discount: 50, paid_amount: 150, start_on: Date.current - 6) }

    let(:invoice4) { create(:invoice, agency:, customer:, amount: 230, additional_charges: 40, discount: 20, paid_amount: 150, start_on: Date.current + 2) }

    let(:invoice5) { create(:invoice, agency:, customer: another_customer, amount: 200, additional_charges: 20, discount: 20, paid_amount: 100, start_on: Date.current - 5) }

    let(:invoice6) { create(:invoice, agency: agency2, customer: customer2, amount: 200, additional_charges: 20, discount: 20, paid_amount: 100, start_on: Date.current - 5) }

    let(:invoice7) { create(:invoice, agency:, customer:, amount: 210, additional_charges: 20, discount: 20, paid_amount: 100, start_on: Date.current - 2) }

    it "should return 0 when no invoices present" do
      expect(customer.past_due_amount).to eq(0)
    end

    it "should return 0 when only one invoice present" do
      [invoice]
      expect(customer.past_due_amount).to eq(0)
    end

    it "should return 0 when no unpaid invoices present that is exclude paid invoices" do
      [invoice2, invoice3]
      expect(customer.past_due_amount).to eq(0)
    end

    it "should exclude other customer invoices" do
      [invoice, invoice4, invoice5]
      expect(customer.past_due_amount).to eq(110)
    end

    it "should exclude other agency's customer invoices" do
      [invoice, invoice4, invoice6]
      expect(customer.past_due_amount).to eq(110)
    end

    it "should include all past invoices" do
      [invoice, invoice4, invoice7]
      expect(customer.past_due_amount).to eq(220)
    end
  end

  describe "#advance_amount" do
    let(:transaction_owner) { create(:user) }
    let(:receiver) { create(:user) }
    let(:agency) { create(:agency) }
    let(:agency2) { create(:agency) }

    let(:customer_group) { create(:customer_group, agency:) }
    let(:customer_group2) { create(:customer_group, agency: agency2) }

    let(:customer) { create(:customer, agency:, customer_group:) }
    let(:another_customer) { create(:customer, agency:, customer_group:) }
    let(:customer2) { create(:customer, agency: agency2, customer_group: customer_group2) }

    let(:payment) { create(:payment, customer:, agency:, transaction_owner:, receiver:, amount: 200, settled_amount: 120) }

    let(:payment2) { create(:payment, customer:, agency:, transaction_owner:, receiver:, amount: 200, settled_amount: 80) }

    let(:payment3) { create(:payment, customer:, agency:, transaction_owner:, receiver:, amount: 80, settled_amount: 80) }

    let(:payment4) { create(:payment, customer: another_customer, agency:, transaction_owner:, receiver:, amount: 160, settled_amount: 80) }

    let(:payment5) { create(:payment, customer: customer2, agency: agency2, transaction_owner:, receiver:, amount: 320, settled_amount: 120) }

    it "should exclude discarded payments" do
      [payment, payment2]
      payment.discard
      expect(customer.advance_amount).to eq(120)
    end

    it "sholud exclude payments where amount eq to sattled_amount" do
      [payment, payment2, payment3]
      expect(customer.advance_amount).to eq(200)
    end

    it "sholud exclude other customer's payment" do
      [payment, payment2, payment4]
      expect(customer.advance_amount).to eq(200)
    end

    it "sholud exclude other agency's customer payments" do
      [payment, payment2, payment5]
      expect(customer.advance_amount).to eq(200)
    end

    it "should return 0 when no advance amount" do
      [payment3]
      expect(customer.advance_amount).to eq(0)
    end
  end

  describe "wallet balance" do
    let(:agency_owner) { create(:user, :agency_owner) }
    let(:agency) { create(:agency) }
    let(:customer_group) { create(:customer_group, agency: agency) }
    let(:customer) { create(:customer, customer_group: customer_group, agency: agency) }

    context "when there is some wallet balance" do
      it "should return wallet balance" do
        create(:invoice, customer: customer, agency: agency, amount: 100, paid_amount: 50, discount: 20, additional_charges: 10)
        create(:invoice, customer: customer, agency: agency, amount: 100, paid_amount: 50, discount: 20, additional_charges: 10)
        create(:payment, amount: 100, settled_amount: 40, payment_date: Date.today, customer: customer, agency: agency, transaction_owner_id: agency_owner.id)
        expect(customer.wallet_balance).to eq(20)
      end
    end

    context "when wallet balance is zero" do
      it "should return zero if balance is zero or negative " do
        expect(customer.wallet_balance).to eq(0)
      end
    end
  end

  describe "#language_preference" do
    it "should return en" do
      agency = create(:agency)
      customer_group = create(:customer_group, agency:)
      customer = create(:customer, agency:, customer_group:)

      expect(customer.language_preference).to eq("en")
    end
  end

  describe "#ledger" do
    let(:transaction_owner) { create(:user) }
    let(:receiver) { create(:user) }

    let(:agency) { create(:agency) }

    let(:customer_group) { create(:customer_group, agency:) }

    let(:customer) { create(:customer, agency:, customer_group:) }
    let(:another_customer) { create(:customer, agency:, customer_group:) }

    let(:invoice) { create(:invoice, agency:, customer:, amount: 520, additional_charges: 20, paid_amount: 210, discount: 10, start_on: Date.current + 5, total_gst_amount: 150) }
    let(:invoice2) { create(:invoice, agency:, customer:, amount: 410, additional_charges: 20, paid_amount: 100, discount: 10, start_on: Date.current - 3, total_gst_amount: 200) }
    let(:invoice3) { create(:invoice, agency:, customer: another_customer, amount: 410, additional_charges: 20, paid_amount: 100, discount: 10, start_on: Date.current - 2) }

    let(:payment) { create(:payment, customer:, agency:, transaction_owner:, receiver:, amount: 200, settled_amount: 120, payment_date: Date.current + 2) }
    let(:payment2) { create(:payment, customer:, agency:, transaction_owner:, receiver:, amount: 680, settled_amount: 255, payment_date: Date.current - 1) }
    let(:payment3) { create(:payment, customer: another_customer, agency:, transaction_owner:, receiver:, amount: 680, settled_amount: 255, payment_date: Date.current - 5) }

    it "should return [] when cutomer do not have payments and invoices" do
      expect(customer.ledger).to eq([])
    end

    it "should return json with invoice for customer when only invoice present" do
      [invoice]
      expected_result = [{ "id" => "i-#{invoice.id}",
                           "amount" => (invoice.amount + invoice.additional_charges - invoice.discount + invoice.total_gst_amount).to_s,
                           "ledger_type" => "invoice",
                           "transaction_date" => invoice.start_on.to_s }]
      expect(customer.ledger).to eq(expected_result)
    end

    it "should return json with payments for customer when only payment present" do
      [payment]

      expected_result = [{ "id" => "p-#{payment.id}",
                           "amount" => payment.amount.to_s,
                           "ledger_type" => "payment",
                           "transaction_date" => payment.payment_date.to_s }]
      expect(customer.ledger).to eq(expected_result)
    end

    it "should return json with payments and invoice for customer when both present" do
      [payment, invoice]
      expected_result = [{ "id" => "i-#{invoice.id}",
                           "amount" => (invoice.amount + invoice.additional_charges - invoice.discount + invoice.total_gst_amount).to_s,
                           "ledger_type" => "invoice",
                           "transaction_date" => invoice.start_on.to_s },
                         { "id" => "p-#{payment.id}",
                           "amount" => payment.amount.to_s,
                           "ledger_type" => "payment",
                           "transaction_date" => payment.payment_date.to_s }]
      expect(customer.ledger).to eq(expected_result)
    end

    it "should return json with payments and invoice for all when there is more than one invoice and payments present" do
      [payment, payment2, invoice, invoice2]

      expected_result = [{ "id" => "i-#{invoice.id}",
                           "amount" => (invoice.amount + invoice.additional_charges - invoice.discount + invoice.total_gst_amount).to_s,
                           "ledger_type" => "invoice",
                           "transaction_date" => invoice.start_on.to_s },

                         { "id" => "p-#{payment.id}",
                           "amount" => payment.amount.to_s,
                           "ledger_type" => "payment",
                           "transaction_date" => payment.payment_date.to_s },

                         { "id" => "p-#{payment2.id}",
                           "amount" => payment2.amount.to_s,
                           "ledger_type" => "payment",
                           "transaction_date" => payment2.payment_date.to_s },

                         { "id" => "i-#{invoice2.id}",
                           "amount" => (invoice2.amount + invoice2.additional_charges - invoice2.discount + invoice2.total_gst_amount).to_s,
                           "ledger_type" => "invoice",
                           "transaction_date" => invoice2.start_on.to_s }]

      expect(customer.ledger).to eq(expected_result)
    end

    it "sholud exclude discarded payment" do
      [payment, payment2]
      payment2.discard

      expected_result = [{ "id" => "p-#{payment.id}",
                           "amount" => payment.amount.to_s,
                           "ledger_type" => "payment",
                           "transaction_date" => payment.payment_date.to_s }]

      expect(customer.ledger).to eq(expected_result)
    end

    it "sholud exclude payment as well as invoice of other customers" do
      [invoice, invoice3, payment, payment3]

      expected_result = [{ "id" => "i-#{invoice.id}",
                           "amount" => (invoice.amount + invoice.additional_charges - invoice.discount + invoice.total_gst_amount).to_s,
                           "ledger_type" => "invoice",
                           "transaction_date" => invoice.start_on.to_s },
                         { "id" => "p-#{payment.id}",
                           "amount" => payment.amount.to_s,
                           "ledger_type" => "payment",
                           "transaction_date" => payment.payment_date.to_s }]
      expect(customer.ledger).to eq(expected_result)
    end
  end

  describe "db_indexes" do
    it { should have_db_index(:agency_customer_id) }
    it { should have_db_index(:agency_id) }
    it { should have_db_index(:customer_group_id) }
    it { should have_db_index(:discarded_at) }
    it { should have_db_index(:invited_by_id) }
    it { should have_db_index(:owner_user_id) }
  end
end
