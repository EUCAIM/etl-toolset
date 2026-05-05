const express = require("express");
const app = express();
const port = 3000;
const cors = require("cors");
const multer = require("multer");
const path = require("path");
const fs = require("fs");

const db = require("./db");
app.use(cors());
app.use(express.json());

// Configure multer for file uploads
const uploadDir = path.join(__dirname, "uploads");
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// Dataset type to folder mapping
const datasetTypeFolders = {
  clinical_data: "/clinical_data",
  image_metadata: "/image_metadata",
  image_timepoints: "/image_timepoints",
};

// Create dataset type folders
Object.values(datasetTypeFolders).forEach((folderName) => {
  const folderPath = path.join(uploadDir, folderName);
  if (!fs.existsSync(folderPath)) {
    fs.mkdirSync(folderPath, { recursive: true });
  }
});

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    cb(null, file.originalname);
  },
});

const upload = multer({ storage });

app.get("/jobs", async (req, res) => {
  try {
    const query = `SELECT * FROM eucaim_cdm_ingestion.processlog `;
    const { rows } = await db.query(query);
    res.json(rows);
  } catch (err) {
    console.error("Error getting jobs:", err);
    res.status(500).json({ error: "Error getting jobs" });
  }
});

app.get("/jobsCompletion", async (req, res) => {
  try {
    const query = `SELECT * from mappedcodeableconceptsresults`;
    const { rows } = await db.query(query);
    res.json(rows);
  } catch (error) {
    console.log("Error getting jobs completion:", err);
    res.status(500).json({ error: "Error getting jobs completion" });
  }
});

app.put("/upload", upload.fields([{ name: "file" }, { name: "datasetid" }, { name: "datasettype" }]), async (req, res) => {
  try {
    const datasetid = req.body?.datasetid;
    const datasettype = req.body?.datasettype;
    const file = req.files?.file?.[0];

 
    if (!file) {
      return res.status(400).json({ error: "No file uploaded" });
    }

    if (!datasetid || !datasettype) {
      return res.status(400).json({ error: "Missing datasetid or datasettype" });
    }

    // Move file to correct folder based on datasettype
    const folderName = datasetTypeFolders[datasettype] || "default";
    const destinationFolder = path.join(uploadDir, folderName);
    const oldPath = file.path;
    const newPath = path.join(destinationFolder, file.filename);

    fs.renameSync(oldPath, newPath);

    res.json({
      message: "File uploaded successfully",
      file: {
        filename: file.filename,
        originalName: file.originalname,
        size: file.size,
        path: newPath,
      },
      dataset: {
        datasetid,
        datasettype,
      },
    });
  } catch (error) {
    console.error("Error uploading file:", error);
    res.status(500).json({ error: "Error uploading file" });
  }
});

app.listen(port, () => {
  console.log(`Listenning on: http://localhost:${port}`);
});
