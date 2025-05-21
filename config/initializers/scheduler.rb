# config/initializers/scheduler.rb
require "rufus-scheduler"

scheduler = Rufus::Scheduler.singleton

# Run the cleanup job at 3:00 AM every day
scheduler.cron "0 3 * * *" do
  CleanBoletosJob.perform_later
end
