#
# Following the "Principle of least privilege" the user that the application uses to log into the
# DB should only have the permissions needed to meet the requirements of an application.
#
# Here we only allow basic CRUD operations to the app user.
#
# See https://dev.mysql.com/doc/refman/8.0/en/privileges-provided.html
# See https://en.wikipedia.org/wiki/Principle_of_least_privilege
#

CREATE SCHEMA IF NOT EXISTS app;

GRANT CREATE TEMPORARY TABLES ON app.* TO 'appuser';
GRANT DELETE ON app.* TO 'appuser';
GRANT EXECUTE ON app.* TO 'appuser';
GRANT INSERT ON app.* TO 'appuser';
GRANT LOCK TABLES ON app.* TO 'appuser';
GRANT SELECT ON app.* TO 'appuser';
GRANT SHOW VIEW ON app.* TO 'appuser';
GRANT UPDATE ON app.* TO 'appuser';

FLUSH PRIVILEGES;
