-- #############################################################################
-- # Part 1: Run these commands as a PostgreSQL superuser (e.g., 'postgres')   #
-- # while connected to the default 'postgres' database or any maintenance DB. #
-- #############################################################################

CREATE USER amoedo_user WITH PASSWORD 'YOUR_VERY_SECURE_PASSWORD_HERE';

ALTER USER amoedo_user CREATEDB; -- Allows amoedo_user to create new databases

ALTER USER amoedo_user VALID UNTIL 'infinity';

CREATE DATABASE amoedo_app_production OWNER amoedo_user;


-- #############################################################################
-- # Part 2: IMPORTANT - MANUALLY CONNECT to 'amoedo_app_production' DATABASE  #
-- # AS THE SAME SUPERUSER (e.g., 'postgres') BEFORE running the commands below.#
-- #                                                                           #
-- # In psql, you would type:                                                  #
-- # \c amoedo_app_production                                                  #
-- #                                                                           #
-- # Your psql prompt should change to indicate connection to                  #
-- # 'amoedo_app_production' (e.g., postgres@amoedo_app_production=>)          #
-- #############################################################################

-- The following commands MUST be run AFTER connecting to 'amoedo_app_production' as a superuser.

ALTER SCHEMA public OWNER TO amoedo_user;

GRANT USAGE ON SCHEMA public TO amoedo_user;
