const mqtt = require("mqtt");
const db = require("./db");
require("dotenv").config();
const host = process.env.MQTT_HOST || "localhost";
const port = process.env.MQTT_PORT || 5432;
const client = mqtt.connect("mqtt://"+host+":"+port); // Cambia esto si usas otro host/puerto
client.on("connect", () => {
  console.log("Connecting mqtt broker");
  client.subscribe("updates", (err) => {
    if (err) {
      console.error("Error subscribing mqtt", err);
    } else{
      console.log("🟢 MQTT Broker connected");
    }
  });
});

client.on("message", async (topic, message) => {
  try {
    const payload = JSON.parse(message.toString());

    if (payload.reportCreate && payload.reportFilename) {
      const reportId = payload.reportCreate;
      const fileName = payload.reportFilename;
      const query = "INSERT INTO jobs (id, filename, step) VALUES ($1, $2, 0)";
      await db.query(query, [reportId, fileName]);

      console.log(`Inserted : ${reportId}`);
    }
    if(payload.reportStep && payload.reportFileId){
      console.log(payload)
      const fileId = payload.reportFileId;
      const step = payload.reportStep;
      const query = "update jobs set step = $1 where id = $2";
      await db.query(query, [step.trim(), fileId.trim()]);
      console.log(`Updated : ${fileId}`);

    }
  } catch (err) {
    console.error("Error processing mqtt", err);
  }
});

module.exports = client;
