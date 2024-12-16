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

  validates :name, length: { minimum: 3, maximum: 50 }
  validates :name, uniqueness: {
    case_sensitive: false,
    message: 'should be uniq. Please enter another name to identify customer.'
  }
end
