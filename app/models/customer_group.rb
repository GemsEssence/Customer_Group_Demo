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
class CustomerGroup < ApplicationRecord
  include Titleize
  titleizable :name

  validates :name, presence: true
  validates :name, length: { minimum: 3, maximum: 50 }
  validates :name, uniqueness: {
    case_sensitive: false,
    message: 'should be uniq, Group already present with same name.'
  }

  has_many :customers

  scope :default, -> { where(is_default: true) }
  scope :by_name, ->(name) { where('lower(name) ilike ?', "%#{name}%") }

  before_destroy :validate_delete_customer_group

  def validate_delete_customer_group
    errors.add(:base, "you can't delete default user group") if is_default
    throw :abort if errors.any?
  end

  def total_due_amount
    customers.sum(:due_amount)
  end
end

