class AddMemberStoreData < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :cart_data, :json, null: false, default: {}
    add_column :users, :saved_product_ids, :json, null: false, default: []
    add_column :users, :postal_code, :string
    add_column :users, :prefecture, :string
    add_column :users, :address, :string
    add_reference :orders, :user, foreign_key: true
  end
end
