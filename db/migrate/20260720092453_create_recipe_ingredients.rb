class CreateRecipeIngredients < ActiveRecord::Migration[8.0]
  def change
    create_table :recipe_ingredients do |t|
      t.references :recipe,
                   type: :uuid,
                   null: false,
                   foreign_key: true
      t.text :ingredient_text, null: false

      t.timestamps
    end
  end
end
