class CreateRecipes < ActiveRecord::Migration[8.0]
  def change
    create_table :recipes,
                 id: :uuid,
                 default: -> { "gen_random_uuid()" } do |t|
      t.string :title, null: false
      t.integer :prep_time
      t.integer :cook_time
      t.decimal :rating, precision: 3, scale: 2
      t.string :category
      t.string :image_url

      t.timestamps
    end
  end
end
