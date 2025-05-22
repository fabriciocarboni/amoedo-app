# app/jobs/cleanup_expired_short_urls_job.rb
class CleanupExpiredShortUrlsJob < ApplicationJob
  queue_as :default

  def perform
    expired_count = ShortUrl.where("expires_at < ?", Time.current).count

    if expired_count > 0
      Rails.logger.info("CleanupExpiredShortUrlsJob: Found #{expired_count} expired short URLs to delete")

      # Delete expired URLs
      ShortUrl.where("expires_at < ?", Time.current).delete_all

      Rails.logger.info("CleanupExpiredShortUrlsJob: Successfully deleted #{expired_count} expired short URLs")
    else
      Rails.logger.info("CleanupExpiredShortUrlsJob: No expired short URLs found")
    end

    # Log remaining URLs count
    remaining_count = ShortUrl.count
    Rails.logger.info("CleanupExpiredShortUrlsJob: #{remaining_count} valid short URLs remain in the database")
  end
end
