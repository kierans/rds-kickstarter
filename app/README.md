# RDS Kickstarter Sample App

Very basic sample app to help show the use of the RDS Kickstarter in action

## Usage

```
$ npm install

$ PORT=3000 node index.js
```

If no `PORT` is specified the app will default to listening on port 3000.

### Database

To change the database host, edit `config.json`. If using RDS you do not need to decrypt the password, as the app will do it automatically. This is good practise as we should never save cleartext passwords anywhere.

The AWS SDK uses the [default profile](https://docs.aws.amazon.com/sdk-for-javascript/v2/developer-guide/loading-node-credentials-shared.html). To use a named profile set the `AWS_PROFILE` when running the app eg:

```
$ AWS_PROFILE=my_profile node index.js
```


### Endpoints

The app provides two endpoints:

```
GET /customers
```

This lists the customers from the DB

```
PUT /customer/:id
```

Updates a customer by an ID. The input is a JSON payload with the data eg:

```json
{
  "name": "New Name",
  "address": "New address"
}
```
