
-- Create the application database with Rails naming convention
CREATE DATABASE amoedo_app_production;

-- Create the new user with a secure password
CREATE USER amoedo_user WITH PASSWORD '';

-- Make the password valid indefinitely (optional)
ALTER USER amoedo_user VALID UNTIL 'infinity';

-- Add comment for documentation (optional)
COMMENT ON ROLE amoedo_user IS 'Dedicated user for the Amoedo database';

-- Grant database-level privileges (important for Rails)
GRANT ALL PRIVILEGES ON DATABASE amoedo_app_production TO amoedo_user;


-- Grant schema permissions
GRANT ALL PRIVILEGES ON SCHEMA public TO amoedo_user;

-- Set default privileges for future tables
ALTER DEFAULT PRIVILEGES
  FOR USER postgres
  IN SCHEMA public
  GRANT ALL PRIVILEGES ON TABLES TO amoedo_user;

-- Set default privileges for future sequences
ALTER DEFAULT PRIVILEGES
  FOR USER postgres
  IN SCHEMA public
  GRANT ALL PRIVILEGES ON SEQUENCES TO amoedo_user;

-- Set default privileges for future functions
ALTER DEFAULT PRIVILEGES
  FOR USER postgres
  IN SCHEMA public
  GRANT ALL PRIVILEGES ON FUNCTIONS TO amoedo_user;

