# app/jobs/clean_boletos_job.rb
class CleanBoletosJob < ApplicationJob
  queue_as :default

  def perform
    # 1. Clean filesystem files
    clean_filesystem_files

    # 2. Clean all ActiveStorage boleto blobs
    clean_active_storage_blobs
  end

  private

  def clean_filesystem_files
    boletos_dir = Api::Santander::FetchCobrancaService::BOLETOS_DIR

    # Skip if directory doesn't exist
    return unless Dir.exist?(boletos_dir)

    # Find all boleto files
    Dir.glob(File.join(boletos_dir, "*")).each do |file|
      if File.file?(file)
        Rails.logger.info("Removing boleto file: #{file}")
        begin
          File.delete(file)
        rescue => e
          Rails.logger.error("Failed to delete file #{file}: #{e.message}")
        end
      end
    end
  end

  def clean_active_storage_blobs
    # Find all boleto blobs (files that match our pattern)
    boleto_blobs = ActiveStorage::Blob.where("filename LIKE '20%_%.pdf'")

    count = boleto_blobs.count
    Rails.logger.info("Found #{count} boleto blobs to clean up")

    purged_count = 0
    boleto_blobs.find_each do |blob|
      Rails.logger.info("Purging boleto blob: #{blob.filename}")
      begin
        # Delete any attachments first
        ActiveStorage::Attachment.where(blob_id: blob.id).delete_all

        # Then purge the blob
        blob.purge
        purged_count += 1
      rescue => e
        Rails.logger.error("Failed to purge blob #{blob.filename}: #{e.message}")
      end
    end

    Rails.logger.info("Successfully purged #{purged_count} out of #{count} boleto blobs")
  end
end
