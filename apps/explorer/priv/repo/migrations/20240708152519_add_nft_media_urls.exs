defmodule Explorer.Repo.Migrations.AddNftMediaUrls do
  use Ecto.Migration

  def change do
    alter table(:token_instances) do
      add(:metadata, :jsonb, null: true)
    end
  end
end
