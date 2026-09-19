class CreateStore < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :slug, null: false
      t.string :name, null: false
      t.string :english_name, null: false
      t.string :category, null: false
      t.string :image, null: false
      t.text :description, null: false
      t.string :material, null: false
      t.string :size, null: false
      t.string :color, null: false
      t.integer :price, null: false
      t.integer :stock, null: false, default: 0
      t.integer :position, null: false, default: 0
      t.boolean :featured, null: false, default: false
      t.timestamps
    end
    add_index :products, :slug, unique: true
    add_index :products, :category
    add_check_constraint :products, "price > 0", name: "products_positive_price"
    add_check_constraint :products, "stock >= 0", name: "products_nonnegative_stock"

    create_table :orders do |t|
      t.string :number, null: false
      t.string :buyer_key, null: false
      t.string :checkout_key, null: false
      t.string :name, null: false
      t.string :email, null: false
      t.string :postal_code, null: false
      t.string :prefecture, null: false
      t.string :address, null: false
      t.integer :subtotal, null: false, default: 0
      t.integer :shipping, null: false, default: 0
      t.integer :total, null: false, default: 0
      t.timestamps
    end
    add_index :orders, :number, unique: true
    add_index :orders, :checkout_key, unique: true
    add_index :orders, :buyer_key
    add_check_constraint :orders, "subtotal >= 0 AND shipping >= 0 AND total = subtotal + shipping", name: "orders_valid_total"

    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.string :name, null: false
      t.string :image, null: false
      t.integer :unit_price, null: false
      t.integer :quantity, null: false
      t.timestamps
    end
    add_check_constraint :order_items, "quantity > 0 AND quantity <= 20 AND unit_price > 0", name: "order_items_valid_values"
  end
end
