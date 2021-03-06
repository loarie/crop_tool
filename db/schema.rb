# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150815043032) do

  create_table "climates", force: :cascade do |t|
    t.float    "lat"
    t.float    "lon"
    t.integer  "temp"
    t.integer  "prec"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "model_parameters", force: :cascade do |t|
    t.string   "country"
    t.string   "crop"
    t.string   "statistic"
    t.string   "estimated_params"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.string   "priors"
  end

  create_table "reports", force: :cascade do |t|
    t.float    "value"
    t.string   "crop"
    t.string   "statistic"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "country"
    t.string   "city"
    t.float    "lat"
    t.float    "lon"
    t.float    "temp"
    t.float    "prec"
    t.string   "identity"
    t.string   "destination"
  end

  create_table "text_messages", force: :cascade do |t|
    t.string   "to",         limit: 12
    t.string   "from",       limit: 12
    t.string   "body",                  null: false
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

end
