# lib/tasks/santander_remessa.rake
namespace :santander do
  desc "Process Santander remessa files from pending directory and move to processed directory"
  task process_remessa_files: :environment do
    require "fileutils"

    # Define directories
    pending_dir = Rails.root.join("storage", "santander", "remessa", "pending")
    processed_dir = Rails.root.join("storage", "santander", "remessa", "processed")
    failed_dir = Rails.root.join("storage", "santander", "remessa", "failed")

    # Ensure directories exist
    [ pending_dir, processed_dir, failed_dir ].each do |dir|
      FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
    end

    # First, find and delete Zone.Identifier files
    zone_files = Dir.glob(File.join(pending_dir, "*")).select do |file|
      file_basename = File.basename(file)
      file_basename.include?("Zone.Identifier")
    end

    if zone_files.any?
      puts "Found #{zone_files.size} Zone.Identifier file(s) to delete"
      zone_files.each do |file|
        puts "  - Deleting: #{File.basename(file)}"
        FileUtils.rm(file)
      end
    end

    # Get all files in pending directory, excluding hidden files and system files
    files = Dir.glob(File.join(pending_dir, "*")).reject do |file|
      # Skip hidden files and system files
      file_basename = File.basename(file)
      file_basename.start_with?(".") ||                   # Hidden files like .DS_Store
      file_basename == "Thumbs.db" ||                     # Windows thumbnail cache
      file_basename == "desktop.ini" ||                   # Windows folder settings
      !File.file?(file)                                   # Skip directories
    end

    if files.empty?
      puts "No valid files found in #{pending_dir}. Check if there are any files to process."
      next
    end

    puts "Found #{files.size} valid file(s) to process"

    # Process each file
    files.each do |file_path|
      original_filename = File.basename(file_path)
      timestamp = Time.current.strftime("%Y%m%d%H%M%S")

      puts "Processing file: #{original_filename}"

      # Process the file
      processor = Santander::RemessaProcessorService.new(file_path, original_filename)
      result = processor.process

      if result[:success]
        # Move to processed directory with timestamp to avoid name conflicts
        target_path = File.join(processed_dir, "#{timestamp}_#{original_filename}")
        FileUtils.mv(file_path, target_path)

        puts "✅ Successfully processed: #{original_filename}"
        puts "  - Processamento ID: #{result[:processamento_id]}"

        if result[:skipped_registros] && result[:skipped_registros] > 0
          puts "  - Skipped registros: #{result[:skipped_registros]}"

          # Find skipped boleto IDs
          skipped_boleto_ids = find_skipped_boleto_ids(file_path, original_filename, result[:processamento_id])

          if skipped_boleto_ids.empty?
            puts "  - Unable to determine specific boleto IDs for skipped records."
            puts "    This may be due to the unique constraint on 'identificacao_do_boleto_no_banco'."

            # Log all boletos in the current file for debugging
            current_boletos = RemessaSantanderRegistro.where(processamento_id: result[:processamento_id])
                                                    .pluck(:identificacao_do_boleto_no_banco)
            puts "  - Current file contains #{current_boletos.size} boletos."
          else
            puts "  - Skipped boleto IDs:"
            skipped_boleto_ids.each_with_index do |boleto_id, index|
              puts "    #{index + 1}. #{boleto_id}"
            end

            # Try to get more details about these skipped boletos
            skipped_records_details = get_skipped_records_details(skipped_boleto_ids)
            if skipped_records_details.any?
              puts "  - Details for skipped boletos:"
              skipped_records_details.each do |detail|
                puts "    * #{detail}"
              end
            end
          end
        else
          puts "  - All registros processed successfully"
        end
      else
        # Move to failed directory with timestamp
        target_path = File.join(failed_dir, "#{timestamp}_#{original_filename}")
        FileUtils.mv(file_path, target_path)

        puts "❌ Failed to process: #{original_filename}"
        puts "  - Error: #{result[:error]}"

        if result[:already_processed]
          puts "  - File was already processed previously"
        end
      end

      puts "-" * 80
    end
  end

  # Helper method to find skipped boleto IDs
  def find_skipped_boleto_ids(file_path, original_filename, processamento_id)
    # Read the original file to extract all boleto IDs
    begin
      # If the file has already been moved, we can't read it directly
      # So we'll try to infer the skipped IDs by comparing what's in the database
      # with what should have been processed

      # Get all boleto IDs from the current processing
      processed_boleto_ids = RemessaSantanderRegistro.where(processamento_id: processamento_id)
                                                   .pluck(:identificacao_do_boleto_no_banco)

      # Find existing boleto IDs that would have caused duplicates
      existing_boleto_ids = RemessaSantanderRegistro.where(identificacao_do_boleto_no_banco: processed_boleto_ids)
                                                  .where.not(processamento_id: processamento_id)
                                                  .pluck(:identificacao_do_boleto_no_banco)
                                                  .uniq

      # If we found some existing IDs, these are likely the ones that were skipped
      return existing_boleto_ids if existing_boleto_ids.any?

      # Try another approach - look at the raw data from the processor service
      # This is a bit of a hack, but it might work if the file has already been processed
      # We'll try to parse the file again and compare with what's in the database

      # Find the most recent processed file with the same name pattern
      processed_files = Dir.glob(Rails.root.join("storage", "santander", "remessa", "processed", "*_#{original_filename}"))
      if processed_files.any?
        most_recent_file = processed_files.max_by { |f| File.mtime(f) }

        # Re-parse the file to get all boleto IDs
        all_lines = File.readlines(most_recent_file, encoding: "ISO-8859-1:UTF-8")
        header_data = Santander::RemessaHeaderProcessorService.new(all_lines.first).parse
        all_boleto_ids = Santander::RemessaRegistroProcessorService.new(all_lines[1...-1], header_data)
                                                                 .parse
                                                                 .map { |data| data[:identificacao_do_boleto_no_banco] }

        # Compare with what's in the database
        skipped_ids = all_boleto_ids - processed_boleto_ids
        return skipped_ids if skipped_ids.any?
      end

      # If we still can't determine the skipped IDs, try a direct database query
      # to find all boletos with the same nome_arquivo_remessa but different processamento_id
      all_boletos_for_file = RemessaSantanderRegistro.where(nome_arquivo_remessa: original_filename)
                                                   .pluck(:identificacao_do_boleto_no_banco, :processamento_id)

      # Group by boleto ID and find those with multiple processamento_ids
      duplicate_boletos = all_boletos_for_file.group_by(&:first)
                                            .select { |_, records| records.size > 1 }
                                            .keys

      return duplicate_boletos if duplicate_boletos.any?

      # If all else fails, return an empty array
      []
    rescue => e
      Rails.logger.error "Error finding skipped boleto IDs: #{e.message}"
      []
    end
  end

  # Helper method to get details about skipped records
  def get_skipped_records_details(boleto_ids)
    return [] if boleto_ids.empty?

    # Find records with these boleto IDs
    skipped_records = RemessaSantanderRegistro.where(identificacao_do_boleto_no_banco: boleto_ids)
                                            .order(created_at: :desc)

    skipped_records.map do |record|
      "Boleto ID: #{record.identificacao_do_boleto_no_banco}, " \
      "Previously processed on: #{record.created_at.strftime('%Y-%m-%d %H:%M:%S')}, " \
      "Previous processamento_id: #{record.processamento_id}, " \
      "File: #{record.nome_arquivo_remessa}"
    end
  end
end
