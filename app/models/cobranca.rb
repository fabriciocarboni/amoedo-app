class Cobranca < ApplicationRecord
  belongs_to :customer
  belongs_to :remessa, class_name: "RemessaSantanderRegistro", optional: true

  validates :asaas_payment_id, presence: true, uniqueness: true

  # Scopes for common queries
  scope :pending, -> { where(status: "PENDING") }
  scope :paid, -> { where(status: "PAID") }
  scope :overdue, -> { where("due_date < ? AND status = ?", Date.today, "PENDING") }

  # Helper methods
  def paid?
    status == "PAID"
  end

  def overdue?
    due_date < Date.today && status == "PENDING"
  end
end
