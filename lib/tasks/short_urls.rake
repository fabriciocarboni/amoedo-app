# lib/tasks/short_urls.rake
namespace :short_urls do
  desc "Clean up expired short URLs"
  task cleanup: :environment do
    puts "Starting cleanup of expired short URLs..."

    expired_count = ShortUrl.where("expires_at < ?", Time.current).count
    puts "Found #{expired_count} expired short URLs"

    if expired_count > 0
      ShortUrl.where("expires_at < ?", Time.current).delete_all
      puts "Successfully deleted #{expired_count} expired short URLs"
    end

    remaining_count = ShortUrl.count
    puts "#{remaining_count} valid short URLs remain in the database"
  end

  desc "Show statistics about short URLs"
  task stats: :environment do
    # Task implementation
  end
end
