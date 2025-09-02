const express = require("express");
const app = express();
const port = 3000;
const cors = require("cors");

const db = require("./db");
// Carga la conexión a MQTT (se conecta automáticamente)
require("./mqttClient");
app.use(cors());

app.get("/jobs", async (req, res) => {
  try {
    const query = `SELECT * FROM jobs `;
    const { rows } = await db.query(query);
    res.json(rows);
  } catch (err) {
    console.error("Error getting jobs:", err);
    res.status(500).json({ error: "Error getting jobs" });
  }
});

app.get("/jobsCompletion" , async(req, res)=>{
  try{

    const query = `SELECT * from mappedcodeableconceptsresults`
    const {rows} = await db.query(query);
    res.json(rows)
  }
  catch (error){
    console.log("Error getting jobs completion:", err);
    res.status(500).json({error:"Error getting jobs completion"})
  }

})

app.listen(port, () => {
  console.log(`Listenning on: http://localhost:${port}`);
});
