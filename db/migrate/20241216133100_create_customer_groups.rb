class CreateCustomerGroups < ActiveRecord::Migration[7.0]
  def change
    create_table :customer_groups do |t|
      t.string :name
      t.boolean :is_deafult

      t.timestamps
    end
  end
end
