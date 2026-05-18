const { Pool } = require("pg");
require("dotenv").config();
const host = process.env.SHARED_DB_HOST || 'localhost';
const database = process.env.SHARED_DB_NAME || "project-P1-P1";
const user = process.env.SHARED_DB_USERNAME || "postgres";
const password = process.env.SHARED_DB_PASSWORD || "postgres";
const port =  process.env.SHARED_DB_PORT || 5432

const pool = new Pool({
  user: user,
  host: host,
  database: database,
  password: password,
  port: port,
});

pool
  .connect()
  .then(() => console.log("🟢 Conectado a PostgreSQL"))
  .catch((err) => console.error("🔴 Error de conexión a PostgreSQL", err));

module.exports = pool;
