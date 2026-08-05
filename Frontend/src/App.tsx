import React, { useState, useEffect, useMemo } from "react";
import {
  RefreshCw,
  Database,
  AlertCircle,
  CheckCircle,
  Layers,
  ChevronDown,
  ChevronRight,
  Tag,
  Check,
  History,
  Upload,
} from "lucide-react";

//const backendIp = import.meta.env.VITE_BACKEND_IP || "localhost";
const backendIp = "192.168.1.128";
const COMPLETION_RULES: Record<string, number> = {
  clinical_data: 8,
  image_timepoints: 4,
  image_metadata: 3,
};

interface Job {
  id: number;
  filename: string;
  datasetid: string;
  datasettype: string;
  pipelinestage: string;
  stepnumber: number;
  stepname: string;
  level: string;
  status: string;
  message: string;
  timestamp: string;
  processed: boolean;
}

function App() {
  const [jobs, setJobs] = useState<Job[]>([]);
  const [loading, setLoading] = useState(true);
  const [isSyncing, setIsSyncing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [expandedDatasets, setExpandedDatasets] = useState<
    Record<string, boolean>
  >({});
  const [showHistory, setShowHistory] = useState<Record<string, boolean>>({});
  const [draggedZones, setDraggedZones] = useState<Set<string>>(new Set());
  const [uploadingZones, setUploadingZones] = useState<Set<string>>(new Set());
  const dragCounterRef = React.useRef<Record<string, number>>({});
  const fileInputRefs = React.useRef<Record<string, HTMLInputElement | null>>({});

  const toggleDataset = (id: string) => {
    setExpandedDatasets((prev) => ({ ...prev, [id]: !prev[id] }));
  };

  const toggleHistory = (typeKey: string) => {
    setShowHistory((prev) => ({ ...prev, [typeKey]: !prev[typeKey] }));
  };

  const handleFileInputChange = (
    e: React.ChangeEvent<HTMLInputElement>,
    datasetId: string,
    datasetType: string,
  ) => {
    console.log("File input changed:", datasetType);
    const files = Array.from(e.target.files || []);
    if (files.length > 0 && files[0].type === "text/csv") {
      uploadFiles(files, datasetId, datasetType);
    }
    // Reset the input so the same file can be selected again
    e.target.value = "";
  };

  const triggerFileInput = (typeKey: string) => {
    fileInputRefs.current[typeKey]?.click();
  };

  const uploadFiles = async (
    files: File[],
    datasetId: string,
    datasetType: string,
  ) => {
    const typeKey = `${datasetId}-${datasetType}`;
    setUploadingZones((prev) => new Set([...prev, typeKey]));
    console.log("Uploading files for:", files[0]);
    try {
      for (const file of files) {
        const formData = new FormData();
        formData.append("file", file);
        formData.append("datasetid", datasetId);
        formData.append("datasettype", datasetType);

        const response = await fetch(`http://${backendIp}:3000/upload`, {
          method: "PUT",
          body: formData,
        });

        if (!response.ok) {
          throw new Error(
            `Upload failed for ${file.name}: ${response.statusText}`,
          );
        }
      }

      // Refresh jobs after successful upload
      await fetchJobs();
    } catch (err) {
      setError(
        err instanceof Error
          ? err.message
          : "An error occurred during file upload",
      );
    } finally {
      setUploadingZones((prev) => {
        const next = new Set(prev);
        next.delete(typeKey);
        return next;
      });
    }
  };

  const handleDragOver = (e: React.DragEvent, typeKey: string) => {
    e.preventDefault();
    e.stopPropagation();
    setDraggedZones((prev) => new Set([...prev, typeKey]));
  };

  const handleDragLeave = (e: React.DragEvent, typeKey: string) => {
    e.preventDefault();
    e.stopPropagation();
    // Decrement the drag counter for this zone
    if (!dragCounterRef.current[typeKey]) {
      dragCounterRef.current[typeKey] = 0;
    }
    dragCounterRef.current[typeKey]--;

    // Only remove from dragged zones when counter reaches 0
    if (dragCounterRef.current[typeKey] <= 0) {
      dragCounterRef.current[typeKey] = 0;
      setDraggedZones((prev) => {
        const next = new Set(prev);
        next.delete(typeKey);
        return next;
      });
    }
  };

  const handleDragEnter = (e: React.DragEvent, typeKey: string) => {
    e.preventDefault();
    e.stopPropagation();
    // Increment the drag counter for this zone
    if (!dragCounterRef.current[typeKey]) {
      dragCounterRef.current[typeKey] = 0;
    }
    dragCounterRef.current[typeKey]++;
    setDraggedZones((prev) => new Set([...prev, typeKey]));
  };

  const handleDrop = (
    e: React.DragEvent,
    datasetId: string,
    datasetType: string,
  ) => {
    e.preventDefault();
    e.stopPropagation();
    const typeKey = `${datasetId}-${datasetType}`;
    // Reset the drag counter and state
    dragCounterRef.current[typeKey] = 0;
    setDraggedZones((prev) => {
      const next = new Set(prev);
      next.delete(typeKey);
      return next;
    });

    const files = Array.from(e.dataTransfer.files);
    if (files.length > 0 && files[0].type === "text/csv") {
      console.log("11File input changed:", files);

      uploadFiles(files, datasetId, datasetType);
    }else{
      setError("Only CSV files are allowed for upload.");
    }
  };

  const fetchJobs = async (silent = false) => {
    try {
      if (!silent) setLoading(true);
      setIsSyncing(true);
      setError(null);
      const response = await fetch(`http://${backendIp}:3000/jobs`);
      if (!response.ok) throw new Error(`Fetch failed: ${response.status}`);
      const data = await response.json();
      setJobs(data);

      setExpandedDatasets((prev) => {
        const next = { ...prev };
        data.forEach((job: Job) => {
          const id = job.datasetid === "---" ? "No name" : job.datasetid;
          if (next[id] === undefined) next[id] = true;
        });
        return next;
      });
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "An unknown error occurred",
      );
    } finally {
      setLoading(false);
      setIsSyncing(false);
    }
  };

  useEffect(() => {
    fetchJobs();
    const timer = setInterval(() => fetchJobs(true), 15000);
    return () => clearInterval(timer);
  }, []);

  // --- Logic to get ONLY the latest version of every step ---
  const processedData = useMemo(() => {
    const grouped: Record<
      string,
      Record<string, { latest: Job[]; history: Job[] }>
    > = {};

    jobs.forEach((job) => {
      const dId = job.datasetid === "---" ? "No name" : job.datasetid;
      const dType = job.datasettype || "General";

      if (!grouped[dId]) grouped[dId] = {};
      if (!grouped[dId][dType])
        grouped[dId][dType] = { latest: [], history: [] };

      grouped[dId][dType].history.push(job);
    });

    // For every dataset type, filter the "latest" view
    Object.keys(grouped).forEach((dId) => {
      Object.keys(grouped[dId]).forEach((dType) => {
        const allJobs = grouped[dId][dType].history.sort(
          (a, b) =>
            new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime(),
        );

        // Map to keep only the newest instance of each step number
        const latestStepsMap = new Map<number, Job>();
        allJobs.forEach((job) => {
          if (!latestStepsMap.has(job.stepnumber)) {
            latestStepsMap.set(job.stepnumber, job);
          }
        });

        grouped[dId][dType].latest = Array.from(latestStepsMap.values()).sort(
          (a, b) => a.stepnumber - b.stepnumber,
        );
        // Sort history by time descending
        grouped[dId][dType].history = allJobs;
      });
    });

    return grouped;
  }, [jobs]);

  const isTypeComplete = (type: string, latestJobs: Job[]) => {
    const targetStep = COMPLETION_RULES[type];
    if (!targetStep) return false;
    // Rule: The step that is >= targetStep must be the one with the LATEST overall timestamp in the group
    const mostRecentJob = [...latestJobs].sort(
      (a, b) =>
        new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime(),
    )[0];

    return (
      mostRecentJob &&
      mostRecentJob.stepnumber >= targetStep &&
      mostRecentJob.status === "OK"
    );
  };

  return (
    <div className="min-h-screen bg-slate-50 p-4 md:p-8">
      <div className="max-w-6xl mx-auto">
        <div className="flex justify-between items-center mb-8">
          <h1 className="text-3xl font-bold text-gray-900 flex items-center gap-2">
            <Layers className="text-blue-600" /> Eucaim ETL Monitor
          </h1>
          <button
            onClick={() => fetchJobs()}
            className="p-2 hover:bg-white rounded-full border shadow-sm transition-all active:scale-95"
          >
            <RefreshCw
              size={18}
              className={
                isSyncing ? "animate-spin text-blue-500" : "text-gray-600"
              }
            />
          </button>
        </div>

        {loading ? (
          <div className="text-center py-20 text-gray-400 font-medium italic">
            Loading...
          </div>
        ) : Object.keys(processedData).length === 0 ? (
          <div className="flex items-center justify-center">
            <div
              onDragEnter={(e) => handleDragEnter(e, "no-dataset-clinical")}
              onDragOver={(e) => handleDragOver(e, "no-dataset-clinical")}
              onDragLeave={(e) => handleDragLeave(e, "no-dataset-clinical")}
              onDrop={(e) => {
                e.preventDefault();
                e.stopPropagation();
                const typeKey = "no-dataset-clinical";
                dragCounterRef.current[typeKey] = 0;
                setDraggedZones((prev) => {
                  const next = new Set(prev);
                  next.delete(typeKey);
                  return next;
                });
                const files = Array.from(e.dataTransfer.files);
                if (files.length > 0 && files[0].type === "text/csv") {
                  const newDatasetId = files[0].name.replace(/\.[^/.]+$/, "");
                  uploadFiles(files, newDatasetId, "clinical_data");
                } else {
                  setError("Only CSV files are allowed for upload.");
                }
              }}
              className={`w-full max-w-2xl bg-white rounded-xl shadow-sm border-2 border-dashed transition-all ${
                draggedZones.has("no-dataset-clinical")
                  ? "border-blue-400 bg-blue-50 shadow-md scale-[1.02]"
                  : "border-gray-300"
              } p-8`}
            >
              <div className="flex flex-col items-center justify-center gap-4">
                <Database className="text-blue-500" size={40} />
                <div className="text-center">
                  <h2 className="text-xl font-bold text-slate-800 mb-2">
                    No Datasets Present
                  </h2>
                  <p className="text-sm text-slate-600 mb-4">
                    Drag and drop a CSV file to create a new clinical data dataset
                  </p>
                </div>
                <button
                  onClick={() => triggerFileInput("no-dataset-clinical")}
                  className="flex items-center gap-2 px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors"
                >
                  <Upload size={16} /> Choose File
                </button>
                <input
                  ref={(el) => {
                    if (el)
                      fileInputRefs.current["no-dataset-clinical"] = el;
                  }}
                  type="file"
                  multiple
                  className="hidden"
                  onChange={(e) => {
                    const files = Array.from(e.target.files || []);
                    if (files.length > 0 && files[0].type === "text/csv") {
                      const newDatasetId = files[0].name.replace(/\.[^/.]+$/, "");
                      uploadFiles(files, newDatasetId, "clinical_data");
                    }
                    e.target.value = "";
                  }}
                />
                {draggedZones.has("no-dataset-clinical") && (
                  <div className="mt-4 text-blue-600 font-medium">
                    Drop files here to upload
                  </div>
                )}
              </div>
            </div>
          </div>
        ) : (
          Object.entries(processedData).map(([datasetId, types]) => (
            <div key={datasetId} className="mb-8">
              <div
                onClick={() => toggleDataset(datasetId)}
                className="flex items-center gap-3 mb-4 cursor-pointer group select-none"
              >
                {expandedDatasets[datasetId] ? (
                  <ChevronDown size={18} />
                ) : (
                  <ChevronRight size={18} />
                )}
                <Database className="text-blue-500" size={20} />
                <h2 className="text-xl font-bold text-slate-800">
                  {datasetId}
                </h2>
              </div>

              {expandedDatasets[datasetId] && (
                <div className="ml-6 space-y-6">
                  {Object.entries(types).map(([type, data]) => {
                    const finished = isTypeComplete(type, data.latest);
                    const typeKey = `${datasetId}-${type}`;
                    const isDragging = draggedZones.has(typeKey);
                    const isUploading = uploadingZones.has(typeKey);

                    return (
                      <div
                        key={type}
                        onDragEnter={(e) => handleDragEnter(e, typeKey)}
                        onDragOver={(e) => handleDragOver(e, typeKey)}
                        onDragLeave={(e) => handleDragLeave(e, typeKey)}
                        onDrop={(e) => handleDrop(e, datasetId, type)}
                        className={`bg-white rounded-xl shadow-sm border transition-all ${
                          isDragging
                            ? "border-blue-400 bg-blue-50 shadow-md scale-[1.02]"
                            : finished
                              ? "border-green-200"
                              : "border-gray-200"
                        } ${isUploading ? "opacity-70" : ""}`}
                      >
                        <div
                          className={`px-4 py-3 border-b flex justify-between items-center ${finished ? "bg-green-50/40" : "bg-slate-50"}`}
                        >
                          <div className="flex items-center gap-4">
                            <div className="flex items-center gap-2">
                              <Tag
                                size={14}
                                className={
                                  finished ? "text-green-600" : "text-slate-400"
                                }
                              />
                              <span className="text-xs font-bold uppercase tracking-wider">
                                {type}
                              </span>
                            </div>
                            <button
                              onClick={() => toggleHistory(typeKey)}
                              className={`flex items-center gap-1 text-[10px] font-bold uppercase px-2 py-1 rounded transition-colors ${showHistory[typeKey] ? "bg-blue-600 text-white" : "bg-slate-200 text-slate-500 hover:bg-slate-300"}`}
                            >
                              <History size={12} />{" "}
                              {showHistory[typeKey]
                                ? "Viewing History"
                                : "View History"}
                            </button>
                            <button
                              onClick={() => triggerFileInput(typeKey)}
                              disabled={isUploading}
                              className="flex items-center gap-1 text-[10px] font-bold uppercase px-2 py-1 rounded bg-blue-500 text-white hover:bg-blue-600 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                            >
                              <Upload size={12} /> Upload Files
                            </button>
                            <input
                              ref={(el) => {
                                if (el) fileInputRefs.current[typeKey] = el;
                              }}
                              type="file"
                              multiple
                              className="hidden"
                              onChange={(e) =>
                                handleFileInputChange(e, datasetId, type)
                              }
                            />
                          </div>

                          {finished && (
                            <div className="flex items-center gap-1.5 px-2 py-0.5 bg-green-500 text-white rounded-full shadow-sm">
                              <Check size={12} strokeWidth={4} />
                              <span className="text-[10px] font-black uppercase">
                                Complete
                              </span>
                            </div>
                          )}
                        </div>

                        {isDragging && (
                          <div className="px-4 py-6 border-b border-blue-200 bg-blue-50 flex flex-col items-center justify-center gap-2">
                            <Upload className="text-blue-500" size={24} />
                            <p className="text-sm font-medium text-blue-600">
                              Drop files here to upload
                            </p>
                          </div>
                        )}

                        {isUploading && (
                          <div className="px-4 py-6 border-b border-blue-200 bg-blue-50 flex flex-col items-center justify-center gap-2">
                            <div className="animate-spin">
                              <RefreshCw className="text-blue-500" size={20} />
                            </div>
                            <p className="text-sm font-medium text-blue-600">
                              Uploading files...
                            </p>
                          </div>
                        )}

                        <div className="overflow-x-auto">
                          <table className="w-full text-left text-sm">
                            <tbody className="divide-y divide-gray-100">
                              {(showHistory[typeKey]
                                ? data.history
                                : data.latest
                              ).map((job) => (
                                <tr
                                  key={job.id}
                                  className={`${showHistory[typeKey] ? "bg-slate-50/30" : ""} hover:bg-blue-50/50 transition-colors`}
                                >
                                  <td className="px-4 py-4 w-12 text-center font-mono text-[10px] text-slate-400">
                                    {job.stepnumber}
                                  </td>
                                  <td className="px-4 py-4">
                                    <div className="font-semibold text-slate-700">
                                      {job.stepname}
                                    </div>
                                    <div className="text-[10px] text-slate-400 truncate max-w-xs">
                                      {job.filename}
                                    </div>
                                  </td>
                                  <td className="px-4 py-4 text-xs text-slate-500 italic">
                                    {job.message}
                                  </td>
                                  <td className="px-4 py-4 text-right pr-6">
                                    <div
                                      className={`flex items-center justify-end gap-1.5 ${job.status === "OK" ? "text-green-600" : "text-red-500"}`}
                                    >
                                      <span className="text-[10px] font-bold uppercase tracking-tighter">
                                        {job.status === "OK"
                                          ? "Success"
                                          : "Error"}
                                      </span>
                                      {job.status === "OK" ? (
                                        <CheckCircle size={18} />
                                      ) : (
                                        <AlertCircle size={18} />
                                      )}
                                    </div>
                                    <div className="text-[9px] text-slate-400 mt-1">
                                      {new Date(job.timestamp).toLocaleString()}
                                    </div>
                                  </td>
                                </tr>
                              ))}
                            </tbody>
                          </table>
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          ))
        )
        }
      </div>
    </div>
  );
}

export default App;
