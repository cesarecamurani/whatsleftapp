class AddIngredientTextTrigramIndex < ActiveRecord::Migration[8.0]
  def change
    add_index :recipe_ingredients,
              :ingredient_text,
              using: :gin,
              opclass: :gin_trgm_ops
  end
end
