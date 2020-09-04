"use strict";

const fs = require("fs");
const path = require("path");

const AWS = require("aws-sdk");
const express = require("express");
const mysql = require('mysql2/promise');

const app = express();
app.use(express.json())

const port = process.env.PORT || 3000;

AWS.config.update({ region: "ap-southeast-2" });
const kms = new AWS.KMS();

(async function() {
	const config = await loadConfig();

	const connection = await mysql.createConnection(config);

	app.get("/customers", async (req, res) => {
		console.log("Listing customers");

		const [ rows ] = await connection.execute("SELECT * FROM `customer`");

		res.send(rows);
	});

	app.put("/customer/:id", async (req, res) => {
		const id = req.params.id;
		const details = req.body;

		console.log(`Updating customer ${id}`);

		try {
			await connection.execute(
				"UPDATE customer SET name = ?, address = ? WHERE id = ?",
				[ details.name, details.address, id ]
			);

			res.send();
		}
		catch (e) {
			console.error(e);

			res.status(500).send(e.message);
		}
	});

	app.listen(port, () => {
		console.log(`App listening at http://localhost:${port}`)
	});
}());

async function loadConfig() {
	const config = JSON.parse(await fs.promises.readFile(path.join(__dirname, "config.json"), { encoding: "utf8" }));

	if (config.ssl !== null) {
		config.ssl.ca = await fs.promises.readFile(path.join(__dirname, config.ssl.ca))

		if (config.host === "localhost") {
			// this is because the SSL cert is self signed and node would reject it otherwise.
			config.ssl.rejectUnauthorized = false;
		}
		else {
			config.password = await decryptString(config.password);
		}
	}
	else {
		delete config.ssl;
	}

	return config;
}

async function decryptString(str) {
	const result = await kms.decrypt({
		CiphertextBlob: Buffer.from(str, "base64")
	})
	.promise();

	return result.Plaintext.toString("utf8");
}

