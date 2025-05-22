# app/controllers/downloads_controller.rb
class DownloadsController < ApplicationController
  # Use the provided class method to skip authentication for the show action
  allow_unauthenticated_access only: [ :show ], if: -> { params[:token].present? }

  # Keep your existing CSRF skip
  skip_before_action :verify_authenticity_token, only: [ :show ]

  rescue_from ActiveStorage::FileNotFoundError, with: :handle_file_not_found

  def show
  # Find the blob using the short URL token
  blob = ShortUrlService.get_blob_from_token(params[:token])

  if blob.nil?
    # Handle not found or expired
    Rails.logger.info("File not found or link expired for token: #{params[:token]}")
    render plain: "File not found or link expired", status: :not_found
    return
  end

  # Get the original filename from ShortUrl model
  short_url = ShortUrl.find_by(token: params[:token])
  original_filename = short_url&.filename || blob.filename.to_s

  # Log the access
  Rails.logger.info("Serving file: #{original_filename} (#{blob.content_type}) for token: #{params[:token]}")

  # Serve the file with the original filename
  serve_blob(blob, original_filename)
  end

  private

  # def allow_public_access
  #   # This method does nothing, effectively bypassing authentication for the show action
  #   true
  # end

  private

  def serve_blob(blob, filename = nil)
    # Use the provided filename or fall back to blob's filename
    filename ||= blob.filename.to_s

    # Set caching headers
    expires_in 1.hour, public: true
    response.headers["Cache-Control"] = "public, max-age=3600"
    response.headers["ETag"] = blob.checksum

    # Set appropriate content type
    response.headers["Content-Type"] = blob.content_type

    # Determine disposition based on content type
    disposition = determine_disposition(blob.content_type)

    # Set content disposition header with the original filename
    response.headers["Content-Disposition"] = ActionDispatch::Http::ContentDisposition.format(
      disposition: disposition,
      filename: filename
    )

    # Stream the file based on storage service
    begin
      if Rails.application.config.active_storage.service == :local
        # For local disk storage
        file_path = ActiveStorage::Blob.service.path_for(blob.key)

        unless File.exist?(file_path)
          Rails.logger.error("File not found on disk: #{file_path}")
          render plain: "File not found on server", status: :not_found
          return
        end

        send_file file_path,
                  type: blob.content_type,
                  disposition: disposition,
                  filename: filename  # Use the original filename
      else
        # For cloud storage (S3, GCS, etc.)
        data = blob.download
        send_data data,
                  type: blob.content_type,
                  disposition: disposition,
                  filename: filename  # Use the original filename
      end
    rescue StandardError => e
      Rails.logger.error("Error serving file #{filename}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      render plain: "Error accessing file", status: :internal_server_error
    end
  end

  def determine_disposition(content_type)
    # Files that can be displayed inline in a browser
    inline_types = [
      "application/pdf",
      "image/jpeg",
      "image/png",
      "image/gif",
      "image/svg+xml",
      "text/plain",
      "text/html"
    ]

    inline_types.include?(content_type) ? "inline" : "attachment"
  end

  def handle_file_not_found(exception)
    Rails.logger.error("File not found exception: #{exception.message}")
    render plain: "The requested file could not be found", status: :not_found
  end
end
