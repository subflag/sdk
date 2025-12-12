# frozen_string_literal: true

class CreateSubflagFlags < ActiveRecord::Migration[8.1]
  def change
    create_table :subflag_flags do |t|
      t.string :key, null: false
      t.string :value_type, null: false, default: "boolean"
      t.text :value, null: false
      t.boolean :enabled, null: false, default: true
      t.text :description

      # Targeting rules for showing different values to different users
      # Stores an array of { value, conditions } rules as JSON
      # First matching rule wins; falls back to `value` if no match
      t.json :targeting_rules

      t.timestamps
    end

    add_index :subflag_flags, :key, unique: true
  end
end
