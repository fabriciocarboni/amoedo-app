# app/services/short_url_service.rb
class ShortUrlService
  def self.generate_for_blob(blob, expires_in: 30.days)
    # Generate a short, unique token (8 characters should be sufficient)
    token = SecureRandom.alphanumeric(8)

    # Create the short URL record
    short_url = ShortUrl.create!(
      token: token,
      blob_id: blob.signed_id,
      filename: blob.filename.to_s,
      expires_at: Time.current + expires_in
    )

    # Return the token
    short_url.token
  end

  def self.get_blob_from_token(token)
    # Find the short URL record
    short_url = ShortUrl.find_by(token: token)

    # Return nil if not found or expired
    return nil if short_url.nil? || (short_url.expires_at.present? && short_url.expires_at < Time.current)

    # Find the blob
    begin
      ActiveStorage::Blob.find_signed(short_url.blob_id)
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      # Handle invalid signature (blob might have been deleted)
      nil
    end
  end
end
