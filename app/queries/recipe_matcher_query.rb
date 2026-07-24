# frozen_string_literal: true

module RecipeMatcherQuery
  def self.call(
    ingredients:,
    minimum_matched_terms:,
    minimum_matched_ingredients:,
    minimum_recipe_coverage:,
    limit:,
    offset:
  )
    <<~SQL.squish
      WITH search_terms(term) AS (
        VALUES #{search_terms_sql(ingredients)}
      ),
      ingredient_matches AS (
        SELECT
          recipe_ingredients.recipe_id,
          COUNT(DISTINCT search_terms.term)
            AS matched_terms_count,
          COUNT(DISTINCT recipe_ingredients.id)
            AS matched_ingredients_count,
          ARRAY_AGG(DISTINCT search_terms.term)
            AS matched_terms
        FROM search_terms
        INNER JOIN recipe_ingredients
          ON recipe_ingredients.ingredient_text
              ILIKE '%' || search_terms.term || '%'
              ESCAPE '\\'
        GROUP BY recipe_ingredients.recipe_id
      ),
      recipe_matches AS (
        SELECT
          ingredient_matches.*,
          EXISTS (
            SELECT 1
            FROM unnest(ingredient_matches.matched_terms) AS t(term)
            WHERE recipes.title
              ILIKE '%' || t.term || '%'
              ESCAPE '\\'
          ) AS title_match
        FROM ingredient_matches
        INNER JOIN recipes
          ON recipes.id = ingredient_matches.recipe_id
      ),
      ingredient_counts AS (
        SELECT
          recipe_ingredients.recipe_id,
          COUNT(*) AS total_ingredients_count
        FROM recipe_ingredients
        INNER JOIN recipe_matches
          ON recipe_matches.recipe_id = recipe_ingredients.recipe_id
        GROUP BY recipe_ingredients.recipe_id
      )
      SELECT
        recipes.*,
        recipe_matches.matched_terms_count,
        recipe_matches.matched_terms,
        recipe_matches.matched_ingredients_count,
        recipe_matches.title_match,
        ingredient_counts.total_ingredients_count,
        COUNT(*) OVER() AS total_count,
        (
          recipe_matches.matched_ingredients_count::decimal
          / NULLIF(ingredient_counts.total_ingredients_count, 0)
        ) AS coverage_ratio,
        (
          ingredient_counts.total_ingredients_count
          - recipe_matches.matched_ingredients_count
        ) AS missing_recipe_ingredients_count,
        CASE
          WHEN recipes.prep_time IS NULL
            AND recipes.cook_time IS NULL
          THEN 1
          ELSE 0
        END AS missing_time,
        (
          COALESCE(recipes.prep_time, 0)
          + COALESCE(recipes.cook_time, 0)
        ) AS total_time
      FROM recipes
      INNER JOIN recipe_matches
        ON recipe_matches.recipe_id = recipes.id
      INNER JOIN ingredient_counts
        ON ingredient_counts.recipe_id = recipes.id
      WHERE recipe_matches.matched_terms_count >= #{minimum_matched_terms}
        AND recipe_matches.matched_ingredients_count >= 1
        AND (
          recipe_matches.title_match
          OR recipe_matches.matched_ingredients_count
            >= #{minimum_matched_ingredients}
          OR (
            recipe_matches.matched_ingredients_count::decimal
            / NULLIF(ingredient_counts.total_ingredients_count, 0)
          ) >= #{minimum_recipe_coverage}
        )
      ORDER BY
        recipe_matches.matched_terms_count DESC,
        recipe_matches.title_match DESC,
        coverage_ratio DESC,
        recipe_matches.matched_ingredients_count DESC,
        missing_recipe_ingredients_count ASC,
        missing_time ASC,
        total_time ASC,
        recipes.rating DESC NULLS LAST,
        recipes.title ASC,
        recipes.id ASC
      LIMIT #{limit}
      OFFSET #{offset}
    SQL
  end

  def self.search_terms_sql(ingredients)
    ingredients
      .map { |ingredient| ActiveRecord::Base.sanitize_sql_like(ingredient) }
      .map { |ingredient| "(#{ActiveRecord::Base.connection.quote(ingredient)})" }
      .join(", ")
  end

  private_class_method :search_terms_sql
end
