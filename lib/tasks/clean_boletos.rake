# lib/tasks/clean_boletos.rake
namespace :clean_boletos do
  desc "Clean up all boleto files and ActiveStorage blobs"
  task cleanup: :environment do
    puts "Starting cleanup of all boleto files and blobs..."

    # Use the job class directly with perform_now (synchronous execution)
    CleanBoletosJob.perform_now

    puts "Cleanup completed."
  end

  desc "Show statistics about boleto files and blobs"
  task stats: :environment do
    boletos_dir = Api::Santander::FetchCobrancaService::BOLETOS_DIR

    puts "Boleto Statistics:"
    puts "------------------"

    if Dir.exist?(boletos_dir)
      files = Dir.glob(File.join(boletos_dir, "*")).select { |f| File.file?(f) }

      puts "Files in directory: #{files.count}"

      if files.any?
        total_size = files.sum { |f| File.size(f) }
        puts "Total size: #{(total_size.to_f / 1024 / 1024).round(2)} MB"
      end
    else
      puts "Boletos directory does not exist."
    end

    # ActiveStorage blob statistics
    boleto_blobs = ActiveStorage::Blob.where("filename LIKE '20%_%.pdf'")

    puts "\nActiveStorage Boleto Blobs:"
    puts "Total blobs: #{boleto_blobs.count}"

    if boleto_blobs.any?
      total_blob_size = boleto_blobs.sum(:byte_size)
      puts "Total size: #{(total_blob_size.to_f / 1024 / 1024).round(2)} MB"
    end
  end
end
