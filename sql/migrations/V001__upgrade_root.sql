# We want to enforce SSL on all users, but in case MySQL/RDS creates admin without this
# fix it.

#
# Note the user of Flyway placeholder variables. If the env var FLYWAY_PLACEHOLDERS_ROOT_PASSWORD
# is present then Flyway will preprocess this migration and replace the variable with the value
# the env var. This is how you allow for different passwords in different environments without
# hardcoding any passwords into your SQL migrations.
#
# See the `migrate.sh` script for an example of how this variable is set.
# See https://flywaydb.org/documentation/placeholders
#
ALTER USER 'root' IDENTIFIED WITH mysql_native_password BY '${root_password}';
ALTER USER 'root' REQUIRE SSL;
