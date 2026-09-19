# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_19_000001) do
  create_table "order_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "image", null: false
    t.string "name", null: false
    t.integer "order_id", null: false
    t.integer "product_id", null: false
    t.integer "quantity", null: false
    t.integer "unit_price", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
    t.check_constraint "quantity > 0 AND quantity <= 20 AND unit_price > 0", name: "order_items_valid_values"
  end

  create_table "orders", force: :cascade do |t|
    t.string "address", null: false
    t.string "buyer_key", null: false
    t.string "checkout_key", null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "number", null: false
    t.string "postal_code", null: false
    t.string "prefecture", null: false
    t.integer "shipping", default: 0, null: false
    t.integer "subtotal", default: 0, null: false
    t.integer "total", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["buyer_key"], name: "index_orders_on_buyer_key"
    t.index ["checkout_key"], name: "index_orders_on_checkout_key", unique: true
    t.index ["number"], name: "index_orders_on_number", unique: true
    t.check_constraint "subtotal >= 0 AND shipping >= 0 AND total = subtotal + shipping", name: "orders_valid_total"
  end

  create_table "products", force: :cascade do |t|
    t.string "category", null: false
    t.string "color", null: false
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.string "english_name", null: false
    t.boolean "featured", default: false, null: false
    t.string "image", null: false
    t.string "material", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.integer "price", null: false
    t.string "size", null: false
    t.string "slug", null: false
    t.integer "stock", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_products_on_category"
    t.index ["slug"], name: "index_products_on_slug", unique: true
    t.check_constraint "price > 0", name: "products_positive_price"
    t.check_constraint "stock >= 0", name: "products_nonnegative_stock"
  end

  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
end
