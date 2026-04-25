require('dd-trace').init();

const express = require("express");
const { Client } = require("pg");
const {
  SecretsManagerClient,
  GetSecretValueCommand,
} = require("@aws-sdk/client-secrets-manager");

const app = express();
const PORT = 3000;

const REGION = process.env.AWS_REGION || "ap-south-1";
const SECRET_NAME = process.env.DB_SECRET_NAME || "node-app-db-secret";

const secretsClient = new SecretsManagerClient({ region: REGION });

let dbClient;

/**
 * Fetch DB credentials from Secrets Manager
 */
async function getDbCredentials() {
  const response = await secretsClient.send(
    new GetSecretValueCommand({
      SecretId: SECRET_NAME,
    })
  );

  return JSON.parse(response.SecretString);
}

/**
 * Initialize DB connection
 */
async function initDb() {
  try {
    const secret = await getDbCredentials();

    dbClient = new Client({
      host: secret.host,
      user: secret.username,
      password: secret.password,
      database: secret.dbname,
      port: secret.port || 5432,
      ssl: { rejectUnauthorized: false }, // required for RDS
    });

    await dbClient.connect();
    console.log("✅ Connected to PostgreSQL");

  } catch (err) {
    console.error("❌ DB connection failed:", err);
  }
}

/**
 * Routes
 */
app.get("/", async (req, res) => {
  res.send("Hello from EKS 🚀");
});

app.get("/db", async (req, res) => {
  try {
    const result = await dbClient.query("SELECT NOW()");
    res.json({ time: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).send("DB error");
  }
});

app.get("/health", (req, res) => res.send("OK"));

/**
 * Start server
 */
app.listen(PORT, async () => {
  console.log(`Server running on port ${PORT}`);
  await initDb();
});