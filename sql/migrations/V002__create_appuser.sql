#
# Again note the use of the Flyway placeholder variables.
#
# We also want to NEVER allow any user to connect to the DB without using SSL so enforce it
#
CREATE USER 'appuser' IDENTIFIED WITH mysql_native_password BY '${appuser_password}' REQUIRE SSL;
