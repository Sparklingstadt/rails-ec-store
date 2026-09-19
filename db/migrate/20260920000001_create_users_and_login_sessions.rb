class CreateUsersAndLoginSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.boolean :admin, null: false, default: false
      t.timestamps
    end
    add_index :users, :email, unique: true

    create_table :login_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.datetime :expires_at, null: false
      t.timestamps
    end
  end
end
