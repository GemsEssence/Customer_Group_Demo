class CreateCustomers < ActiveRecord::Migration[7.0]
  def change
    create_table :customers do |t|
      t.string :name
      t.string :email
      t.string :mobile_no
      t.string :address
      t.boolean :is_active
      t.references :customer_group, null: false, foreign_key: true
      t.decimal :due_amount
      t.integer :position

      t.timestamps
    end
  end
end
