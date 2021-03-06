class Statistic < ApplicationRecord
  self.primary_key = :id
  paginates_per 10

  belongs_to :broadcast, foreign_key: :id

  private

  # this isn't strictly necessary, but it will prevent
  # rails from calling save, which would fail anyway.
  def readonly?
    true
  end
end
