class EnablePostgresqlExtensions < ActiveRecord::Migration[8.0]
  def change
    enable_extension "pg_trgm"
    enable_extension "pgcrypto"
  end
end
