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
class Customer < ApplicationRecord
  include Titleize
  titleizable :name

  belongs_to :customer_group

  validates :name, :mobile_no, presence: true

  validates :mobile_no, uniqueness: {
    case_sensitive: false,
    message: 'should be uniq. Customer already exists with same mobile no.'
  }

  AVAILABLE_SHIFTS = [:morning, :afternoon, :evening].freeze

  validates :name, length: { minimum: 3, maximum: 50 }
  validates :name, uniqueness: {
    case_sensitive: false,
    message: 'should be uniq. Please enter another name to identify customer.'
  }

  scope :active_customer, -> { where(is_active: true)}

  scope :by_name, ->(search_term) {
    where('lower(name) LIKE ? OR mobile_no LIKE ?', "%#{search_term.downcase}%", "%#{search_term}%")
  }

  def associated_customers_from_customer_group
    self.customer_group.customers
  end

  def active_associated_customers_from_customer_group
    associated_customers_from_customer_group.active_customer
  end
  
  def language_preference
    "en"
  end
end
