# app/jobs/clean_boletos_job.rb
class CleanBoletosJob < ApplicationJob
  queue_as :default

  def perform
    # Keep boletos for 7 days (adjust as needed)
    retention_period = 1.days
    cutoff_time = Time.now - retention_period

    boletos_dir = Api::Santander::FetchCobrancaService::BOLETOS_DIR

    # Skip if directory doesn't exist
    return unless Dir.exist?(boletos_dir)

    # Find files older than the cutoff time
    Dir.glob(File.join(boletos_dir, "*")).each do |file|
      if File.file?(file) && File.mtime(file) < cutoff_time
        Rails.logger.info("Removing old boleto file: #{file}")
        File.delete(file)
      end
    end

    # Also clean up ActiveStorage blobs
    ActiveStorage::Blob.where("created_at < ?", cutoff_time).find_each do |blob|
      if blob.filename.to_s.start_with?(/\d{14}_/) # Match our timestamp prefix
        Rails.logger.info("Removing old boleto blob: #{blob.filename}")
        blob.purge
      end
    end
  end
end
