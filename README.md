# RDS Kickstarter

A starting project for learning how to run a MySQL Docker image locally for development and the same schema in [RDS](https://aws.amazon.com/rds/) in a secure and maintainable way.

This kickstarter is designed to demonstrate:
 - How to use the [12 Factor App](https://12factor.net/) principles to break config (eg: passwords) from code (the schema DDL) making the DDL useable in any environment.
 - How to contribute to the security of ["data in transit"](https://en.wikipedia.org/wiki/Data_in_transit) by enforcing the use of SSL (with a minimum of TLS 1.2) for DB client connections (security of ["data at rest"](https://en.wikipedia.org/wiki/Data_at_rest) is outside the scope of this project, but can easily be achieved by enabling encryption options in RDS)
 - How schemas can evolve along with the rest of the code required for the application.

If you're not familiar with the term, an "environment" is the collection of resources required to run a version of
software. For a web application this would be the DB instance, and the web server, as well as any other infrastructure required to run the application eg: SSL certificates if you wanted to serve the application over HTTPS.

We can have many environments running different versions of the resources to develop and test changes to the application as well as have the "production" environment which is the environment used to enable customers to use the application.

When we have many environments (local, test, prod, etc) we have to have a reliable, repeatable mechanism to deploy versions of the code into that environment to be confident our software will work.

This kickstarter demonstrates how to meet the goal of having a reliable deployments with a RDBMS - specifically MySQL. We use Docker for local development and RDS for our test/prod environments.

## Getting started

The first step is to install [Docker](https://www.docker.com/) and learn how [Docker can help](https://www.docker.com/resources/what-container) kill the dreaded "but it works on my machine" problem. This project runs a full MySQL instance, and a Java based migration tool all without you having to install MySQL or Java (and associated tools like Maven).

This project uses [Docker Compose](https://docs.docker.com/compose/) and some Bash scripts to orchestrate the use of Docker and RDS.

The Bash scripts use the [npm json](https://www.npmjs.com/package/json) tool which can be installed via npm

```
# you may have to use sudo based on your file permissions
$ npm install -g json
```

Bash 5 is recommended.

Read the comments in the files for more info on what they do and how they work.

### AWS Profile

The scripts that act against RDS use the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html) and require that the [AWS Profile](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html) used has the correct IAM permissions to create an RDS instance, and to use KMS for decrypting passwords.

The scripts cannot exceed the permissions that the AWS user itself has. If you have more than one set of AWS CLI credentials use a [Named Profile](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html) and set `AWS_PROFILE` to the correct profile for your shell. 

#### Creating an RDS

An RDS instance can be created either by using the RDS console, or the `create-rds.sh` script (which uses the `aws` cli tool). Make sure that the `credentials.json` has the correct credentials for the RDS instance/environment.

If using the RDS console you will have to use the encrypted passwords.

If using the `create-rds.sh` script the passwords will decrypted and used when creating the RDS.

If you want to add encryption options, you'll need to create a key in KMS and pass the key alias to RDS at creation time.

## The DB migration problem

When developing applications that require the use of an RDBMS there are several problems that often arise.

1. How to keep different environments in sync so that schema changes can be propagated in a deterministic way.
2. How to manage credentials across environments as there many be many users in the database from the root/admin user to an "application user" that has limited permissions in the database. If there are different credentials per user per enviroment, we need a way to apply the correct configuation with the schemas at deployment time.
3. How to develop/test locally and then deploy changes to a "test" or "production" database running in RDS.

### Synchronising change

The biggest issue with using a RDBMS in a multi environment, multi technology mix is keeping the database schemas in sync with each other and the applications that use the database. For example if you have a `customer` table and a later version of an application tries to save an `address`, if the DB schema change to create the `address` column is not propagated consistently then the application may error, or crash. 

The **worst thing** you can do is run DDL manually. Inevitable someone will make a mistake and then your environments will be out of sync, with a lot of time spent figuring out why, and possibly production support phone calls at 0300.

In this project we consider 3 environments each with their own instance of MySQL:
- `local` - your laptop
- `test` - a test environment running in RDS
- `prod` - your production environment running in RDS.

(Note: if you do create multiple RDS instances; don't forget to delete them when you're not using them, or you might have a very expensive AWS bill!!)

The correct way to apply changes (migrations) to databases is with a DB migration tool like [Flyway](https://flywaydb.org/) where you create a set of versioned (with your VCS like Mercurial or Git) migrations that are applied in sequence. Flyway records what migrations have been applied in the DB so that it knows what version the DB is at. As the schemas evolve, just like code evolves, the DB is migrated to a version required to match the needs of the application using the DB.

#### How to apply migrations

The `migrate-local.sh` and `migrate-rds.sh` scripts are designed to run Flyway (in a Docker container) against either a local DB (running in Docker) or an RDS instance. This shows the 12 Factor App principles in action by keeping the schemas environment agnostic (no hardcoded clear text passwords!).

The Flyway container uses the root/admin account in the MySQL instance so that it has all the necessary permissions to migrate the DB.

Sample migrations for our app DB are in the `sql/migrations` directory.

The migrations demonstrate the use of

1. Forcing clients to connect to the DB over SSL. MySQL by default does not force the use of SSL. To be secure, we must force the use of SSL.
2. The use of [Flyway Placeholders](https://flywaydb.org/documentation/placeholders) to inject [environment specific details](https://12factor.net/config) (such as passwords) into the scripts at migration time. This allows the DDL to be executed against a local database with a dummy password, or a production database where we want to control who has the password.
3. An application user (`appuser`) that has a limited set of permissions in the DB to prevent accidents.
4. A table in the `app` DB.

Once the migrations are run, a RDBMS tool like [MySQL Workbench](https://www.mysql.com/products/workbench/) or [Data Grip](https://www.jetbrains.com/datagrip/) can be used to connect to the databases either locally or in RDS.

#### Trusting the Database

In order to connect to the MySQL instance using SSL, we have to trust the certificate that the instance presents, and use the key in the certificate to establish the encryped connection. This is usually performed by the MySQL client looking at the certificate chain and looking for a trusted Certificate Authority (CA) that has signed the certificate indicating that the certificate can be trusted.

When the RDS MySQL instance is created, it is provisioned with an SSL certficate [signed by an AWS CA](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MySQL.html#MySQL.Concepts.SSLSupport). However if the client (including Flyway) isn't told to trust the CA, then the MySQL client may refuse to connect to the RDS instance.

MySQL supports varying levels of [SSL modes](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MySQL.html#MySQL.Concepts.SSLSupport) however we require at minimum the `REQUIRED` mode be used to maintain "data in transit" security.

The Flyway Docker image by default uses the `VERIFY_CA` SSL mode so that Flyway will make sure the certificate is legitimate. In The Age Of The Cloud we have to validate the server is who we think it is as resources can come and go at whim. Good developers always verify they are talking to a legitimate server, in our case the RDS host. Fortunately for us, the Flyway Docker image also bundles and trusts the [RDS CA](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.SSL-certificate-rotation.html). This means that when connecting to the RDS instance Flyway will trust the certificate presented (as long as it is signed by the CA we're trusting) and establish the SSL connection to then run the SQL migrations.

However when running MySQL locally, the SSL certificate presented is self signed. This means that the `VERIFY_CA` SSL mode will fail as a self signed certificate will always fail CA verification. This is why the `migrate-local.sh` script uses the `REQUIRED` SSL mode when connecting to the local MySQL Docker container. This is an acceptable security trade off because the MySQL Docker container is most likely running on the same host as the Flyway container (the `docker-compose` file uses a private Docker network for the containers), so we can be confident we're talking to the right MySQL instance.

What we don't want to do is fall for the trap where we disable SSL locally because dealing with SSL is hard. This is because:
1. This breaks the 12 Factor App principle of [minimal divergence](https://12factor.net/dev-prod-parity) between environments.
2. "Dev only" code will inevitably get committed and pushed to a production environment (due to [Murphy's Law](https://en.wikipedia.org/wiki/Murphy%27s_law)). This means that suddenly production will no longer mandates the use of SSL which mean a client may connect via an unecrypted session weakening the security of our application.

#### Connecting MySQL Client over SSL

Just like we have to get Flyway to trust the DB SSL certificate when connecting with our SQL dev tool eg: MySQL Workbench, we have to configure the tool to use SSL

##### Java based tools

Java based tools like [Squirrel](https://sourceforge.net/projects/squirrel-sql/) or Data Grip use [JDBC Drivers](https://en.wikipedia.org/wiki/Java_Database_Connectivity). The MySQL project produces a [JDBC Driver](https://dev.mysql.com/doc/connector-j/8.0/en/) JAR. If your tool does not have the MySQL Connector J JAR, you will need to [download it](https://dev.mysql.com/doc/connector-j/8.0/en/connector-j-installing.html) and make it available to the tool. Most tools should ship with it given the popularity of MySQL.

The [URL format](https://dev.mysql.com/doc/connector-j/8.0/en/connector-j-reference-jdbc-url-format.html) for the connection is either (note the use of the SSL mode)

```
# For local dev
jdbc:mysql://localhost:3306?sslMode=REQUIRED&enabledTLSProtocols=TLSv1.2

# For RDS
jdbc:mysql://<RDS hostname.rds.amazonaws.com>:3306?sslMode=VERIFY_CA&enabledTLSProtocols=TLSv1.2
```

The final step is to have the tool trust the RDS CA. The `javax.net.ssl.trustStore` and `javax.net.ssl.trustStorePassword` [System properties](https://howtodoinjava.com/java/basics/java-system-properties/) need to set to point to a [JKS](https://en.wikipedia.org/wiki/Java_KeyStore) file with the RDS PEM file in it. The [Flyway Docker JKS](https://github.com/kierans/flyway-mysql-rds/blob/master/opt/rds/rds.jks) can be used by saving the file and have the tool use the JKS for it's truststore (the password is "changeit")

This can be done via modifying the startup script for your tool to include the System Properties (`-D` flags) or by consulting the documentation for the tool.

(If you want to look inside the JKS either the `keytool` JDK CLI tool can be used, or [KeyStore Explorer](https://keystore-explorer.org/))

### Credential Management

When managing credentials for non local environments we want to make sure that only the right people have access. What is important to remember is that plaintext passwords **must never** be checked into VCS. To get around this issue, this project uses KMS to encrypt the passwords and commit the encrypted string to VCS. To decrypt it you must have the correct IAM permisions to have access to the key used in KMS to encrypt the password.

This means that to use this project you will have to create some passwords yourself and use the `encrypt-password.sh` script to encrypt them with KMS.

You should use a different password for every user in the `credentials.json`.

## Exercise 

As a practical exercise to demonstrate the concepts there is a sample app that lists
customers with their addresses.

1. Create the Docker network
    
    `$ docker network create rds-mysql-local-network`
    
2. Run the database using

    `$ docker-compose up`
    
3. Migrate the database (in another terminal)

    `$ cd bin && ./migrate-local.sh rds-mysql-local`

4. Run the sample application (see the README for the app)

5. Query for the customer

   ```
   $ curl http://localhost:3000/customers
   [{"id":1,"name":"Bruce Wayne","created_at":"2020-09-03T12:52:53.907Z","last_updated_at":"2020-09-03T12:52:53.907Z"}] 
   ```

6. Try to update the customer's address

    ```
   $ curl -X PUT -H "Content-Type: application/json" -d '{ "name": "Batman", "address": "Batcave" }' http://localhost:3000/customer/1
   Unknown column 'address' in 'field list'
   ```
   
   The call fails with a 500 because the column doesn't exist.
   
7. Add a new migration to `sql/migrations` to add an `address` column of `VARCHAR(256)` to the `customer` table. Run `migrate-local.sh` to apply the migration.

8. Rerun (6). The app should return a 200 response.

9. Rerun (5). The updated data should be returned.

10. Create an RDS instance.

    ```
    $ cd bin && ./create-rds.sh app-test
    ```

11. Migrate the instance

    ```
    $ cd bin && ./migrate-rds.sh app-test
    ```

    Note: If you're having trouble connecting to the RDS (ie: Flyway times out) try using `telnet`
    
    ```
    $ telnet <rds hostname> 3306
    ```
    
    If telnet is unable to connect to the host, the AWS Security Group (firewall) is possibly blocking the inbound traffic. If you `Modify` the RDS instance in the RDS Console you can see what Security Group is being applied. Either add another SG that allows inbound traffic on port 3306 or alter the SG via the EC2 console to allow inbound traffic on port 3306.
    
12. Run the app pointing to the RDS instance (see `config.rds.json` for an example)

13. Rerun (5) (6) and (5) again.

    The customer data should be updated on the first PUT request. This is because the schema migration to add the `address` column was applied when the `migrate-rds.sh` script was run.
    
Hopefully the exercise has helped demonstrate how to apply the principles discussed in a practical way.

### Bonus exercises

1. Spin up a production database (`app-prod`) and migrate it as well, using different passwords for the `app-test` and `app-prod` profiles.

2. Use [RDS encryption](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Encryption.html) to have the data protected "at rest".

3. Create a Dockerfile that creates an image of the DB with the migrations bundled. This is useful in CI/CD as the image can be tagged and stored in a Container Registry (eg: ECR). That way if you want to run the migrations in a CI tool you can use Docker to orchestrate the application of the migrations.

## Wrapup

This kickstarter has practically demonstrated how to securely and reliably manage a MySQL database running on your local machine and in the cloud on RDS.

Don't forget to delete your RDS instances!!!
