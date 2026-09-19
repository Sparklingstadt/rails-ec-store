class AddOrderStatus < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :status, :string, null: false, default: "placed"
    add_column :orders, :cancelled_at, :datetime
    add_column :orders, :shipped_at, :datetime
    add_index :orders, :status
    add_check_constraint :orders, "status IN ('placed', 'shipped', 'cancelled')", name: "orders_valid_status"
  end
end
