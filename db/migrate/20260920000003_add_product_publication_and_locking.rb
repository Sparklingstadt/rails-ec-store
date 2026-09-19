class AddProductPublicationAndLocking < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :published, :boolean, null: false, default: true
    add_column :products, :lock_version, :integer, null: false, default: 0
    add_index :products, [ :published, :category ]
  end
end
