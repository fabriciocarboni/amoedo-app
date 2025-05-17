# app/models/remessa_santander_trailer.rb
class RemessaSantanderTrailer < ApplicationRecord
  belongs_to :remessa_santander_header, optional: true
  belongs_to :remessa_santander_registros, optional: true

  # Presence and length validations
  validates :codigo_do_registro, presence: true, length: { is: 1 }
  validates :quantidade_de_registros_no_arquivo, presence: true, length: { is: 6 }
  validates :valor_total_dos_boletos, presence: true
  validates :numero_sequencial_de_registros_no_arquivo, presence: true, length: { is: 6 }
end
