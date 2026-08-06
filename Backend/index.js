const express = require("express");
const app = express();
const port = 3000;
const cors = require("cors");
const multer = require("multer");
const path = require("path");
const fs = require("fs");
const crypto = require("crypto");

const db = require("./db");
app.use(cors());
app.use(express.json());

// Must point at the same volume the nifi container mounts as input_data, since
// that is where the loop01 flows list for new dataset files.
const inputDir = process.env.ETL_INPUT_DIR || "/data/input_data";

// Uploads land here first and are then renamed into the watched folder, so NiFi
// never lists a half-written file. Kept as a sibling of the watched folders to
// keep the rename on the same filesystem, and dot-prefixed so that even if it
// were listed, the "[^\.].*" file filters would skip it.
const stagingDir = path.join(inputDir, ".uploads_staging");

// Dataset type -> extensions accepted by the File Filter of the matching loop01 flow
const datasetTypeExtensions = {
  clinical_data: [".csv", ".json", ".xls"],
  image_metadata: [".csv"],
  image_timepoints: [".csv"],
};

fs.mkdirSync(stagingDir, { recursive: true });
Object.keys(datasetTypeExtensions).forEach((datasetType) => {
  fs.mkdirSync(path.join(inputDir, datasetType), { recursive: true });
});

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, stagingDir);
  },
  // The client sends the file part before the text fields, so req.body is still
  // empty here. The final name is resolved in the handler instead.
  filename: (req, file, cb) => {
    cb(null, `.upload_${crypto.randomUUID()}`);
  },
});

const upload = multer({ storage });

// The loop01 flows read the dataset id as ${filename:substringBefore("_"):toLower()},
// so it has to be the lowercased prefix up to the first underscore.
const buildFilename = (datasetid, originalname) => {
  const prefix = datasetid.toLowerCase();
  // basename() keeps a crafted originalname from escaping the input folder
  const name = path.basename(originalname);
  return name.toLowerCase().startsWith(`${prefix}_`) ? name : `${prefix}_${name}`;
};

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
    const query = `SELECT * from eucaim_cdm_ingestion.mappedcodeableconceptsresults`;
    const { rows } = await db.query(query);
    res.json(rows);
  } catch (error) {
    console.log("Error getting jobs completion:", error);
    res.status(500).json({ error: "Error getting jobs completion" });
  }
});

app.put("/upload", upload.fields([{ name: "file" }, { name: "datasetid" }, { name: "datasettype" }]), async (req, res) => {
  const file = req.files?.file?.[0];
  // Anything that does not reach the input folder has to be dropped, otherwise
  // rejected uploads pile up in the staging folder.
  const discardStaged = () => {
    if (file) fs.rmSync(file.path, { force: true });
  };

  try {
    const datasetid = req.body?.datasetid;
    const datasettype = req.body?.datasettype;

    if (!file) {
      return res.status(400).json({ error: "No file uploaded" });
    }

    if (!datasetid || !datasettype) {
      discardStaged();
      return res.status(400).json({ error: "Missing datasetid or datasettype" });
    }

    const allowedExtensions = datasetTypeExtensions[datasettype];
    if (!allowedExtensions) {
      discardStaged();
      return res.status(400).json({
        error: `Unknown datasettype "${datasettype}". Expected one of: ${Object.keys(datasetTypeExtensions).join(", ")}`,
      });
    }

    // An underscore would be truncated by substringBefore("_") and yield the
    // wrong dataset id; a path separator would escape the input folder.
    if (!/^[A-Za-z0-9-]+$/.test(datasetid)) {
      discardStaged();
      return res.status(400).json({
        error: "Invalid datasetid: only letters, digits and hyphens are allowed",
      });
    }

    const filename = buildFilename(datasetid, file.originalname);
    const extension = path.extname(filename).toLowerCase();
    if (!allowedExtensions.includes(extension)) {
      discardStaged();
      return res.status(400).json({
        error: `NiFi does not pick up "${extension}" files for ${datasettype}. Expected one of: ${allowedExtensions.join(", ")}`,
      });
    }

    // Same filesystem as the staging folder, so this is atomic and NiFi only
    // ever lists the finished file.
    const destination = path.join(inputDir, datasettype, filename);
    fs.renameSync(file.path, destination);

    res.json({
      message: "File uploaded successfully",
      file: {
        filename,
        originalName: file.originalname,
        size: file.size,
        path: destination,
      },
      dataset: {
        datasetid,
        datasettype,
      },
    });
  } catch (error) {
    console.error("Error uploading file:", error);
    discardStaged();
    res.status(500).json({ error: "Error uploading file" });
  }
});

app.listen(port, () => {
  console.log(`Listenning on: http://localhost:${port}`);
});
