# config/initializers/scheduler.rb
require "rufus-scheduler"

scheduler = Rufus::Scheduler.singleton

# Run the existing cleanup job at 3:00 AM every day
scheduler.cron "0 3 * * 0" do
  CleanBoletosJob.perform_later
end

# Run the ShortURL cleanup job at 4:00 AM every day
scheduler.cron "0 4 * * *" do
  CleanupExpiredShortUrlsJob.perform_later
end
