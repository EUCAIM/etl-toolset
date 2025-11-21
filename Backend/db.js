const { Pool } = require("pg");
require("dotenv").config();
const host = process.env.DB_HOST || 'localhost';
const database = process.env.DB_NAME || "eucaim-nifi-test2";
const user = process.env.DB_USER || "postgres";
const password = process.env.DB_PASSWORD || "postgres";
const port =  process.env.DB_PORT || 5432

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
