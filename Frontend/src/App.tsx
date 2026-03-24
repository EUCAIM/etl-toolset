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
} from "lucide-react";

const backendIp = import.meta.env.VITE_BACKEND_IP || "localhost";

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
  const [secondsUntilRefresh, setSecondsUntilRefresh] = useState(15);
  const [expandedDatasets, setExpandedDatasets] = useState<
    Record<string, boolean>
  >({});

  const toggleDataset = (id: string) => {
    setExpandedDatasets((prev) => ({ ...prev, [id]: !prev[id] }));
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
    const timer = setInterval(() => {
      setSecondsUntilRefresh((prev) => {
        if (prev <= 1) {
          fetchJobs(true);
          return 15;
        }
        return prev - 1;
      });
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  const groupedData = useMemo(() => {
    return jobs.reduce(
      (acc, job) => {
        const dId = job.datasetid === "---" ? "No name" : job.datasetid;
        const dType = job.datasettype || "General";
        if (!acc[dId]) acc[dId] = {};
        if (!acc[dId][dType]) acc[dId][dType] = [];
        acc[dId][dType].push(job);
        return acc;
      },
      {} as Record<string, Record<string, Job[]>>,
    );
  }, [jobs]);

  const isTypeComplete = (type: string, jobsInGroup: Job[]) => {
    const targetStep = COMPLETION_RULES[type];
    if (!targetStep) return false;
    return jobsInGroup.some(
      (job) => job.stepnumber >= targetStep && job.status === "OK",
    );
  };

  return (
    <div className="min-h-screen bg-slate-50 p-4 md:p-8">
      <div className="max-w-6xl mx-auto">
        <div className="flex justify-between items-center mb-8">
          <div>
            <h1 className="text-3xl font-bold text-gray-900 flex items-center gap-2">
              <Layers className="text-blue-600" /> Eucaim ETL Monitor
            </h1>
          </div>
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

        {error && (
          <div className="mb-6 p-4 bg-red-50 border border-red-200 text-red-700 rounded-lg flex items-center gap-3">
            <AlertCircle /> {error}
          </div>
        )}

        {loading ? (
          <div className="text-center py-20 text-gray-400 font-medium italic">
            Initializing pipeline view...
          </div>
        ) : (
          Object.entries(groupedData).map(([datasetId, types]) => (
            <div key={datasetId} className="mb-8">
              <div
                onClick={() => toggleDataset(datasetId)}
                className="flex items-center gap-3 mb-4 cursor-pointer group select-none"
              >
                <div className="transition-transform duration-200">
                  {expandedDatasets[datasetId] ? (
                    <ChevronDown size={18} />
                  ) : (
                    <ChevronRight size={18} />
                  )}
                </div>
                <Database className="text-blue-500" size={20} />
                <h2 className="text-xl font-bold text-slate-800 group-hover:text-blue-600 transition-colors">
                  {datasetId}
                </h2>
              </div>

              {expandedDatasets[datasetId] && (
                <div className="ml-6 space-y-6">
                  {Object.entries(types).map(([type, datasetJobs]) => {
                    const finished = isTypeComplete(type, datasetJobs);

                    return (
                      <div
                        key={type}
                        className={`bg-white rounded-xl shadow-sm border transition-all ${finished ? "border-green-200 shadow-green-50" : "border-gray-200"}`}
                      >
                        <div
                          className={`px-4 py-3 border-b flex justify-between items-center ${finished ? "bg-green-50/40" : "bg-slate-50"}`}
                        >
                          <div className="flex items-center gap-2">
                            <Tag
                              size={14}
                              className={
                                finished ? "text-green-600" : "text-slate-400"
                              }
                            />
                            <span
                              className={`text-xs font-bold uppercase tracking-wider ${finished ? "text-green-700" : "text-slate-600"}`}
                            >
                              {type}
                            </span>
                          </div>

                          {finished && (
                            <div className="flex items-center gap-2">
                              <span className="text-[10px] text-green-600/70 font-medium">
                                Last step reached:{" "}
                                {new Date(
                                  datasetJobs[datasetJobs.length - 1].timestamp,
                                ).toLocaleTimeString([], {
                                  hour: "2-digit",
                                  minute: "2-digit",
                                })}
                              </span>
                              <div className="flex items-center gap-1.5 px-2 py-0.5 bg-green-500 text-white rounded-full shadow-sm">
                                <Check size={12} strokeWidth={4} />
                                <span className="text-[10px] font-black uppercase">
                                  Complete
                                </span>
                              </div>
                            </div>
                          )}
                        </div>

                        <div className="overflow-x-auto">
                          <table className="w-full text-left text-sm">
                            <tbody className="divide-y divide-gray-100">
                              {datasetJobs
                                .sort((a, b) => a.stepnumber - b.stepnumber)
                                .map((job) => (
                                  <tr
                                    key={job.id}
                                    className="hover:bg-slate-50/80 transition-colors"
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
                                    <td className="px-4 py-4 text-xs text-slate-500 italic max-w-sm">
                                      {job.message}
                                    </td>
                                    <td className="px-4 py-4 text-right pr-6">
                                      {job.status === "OK" ? (
                                        <div className="flex items-center justify-end gap-1.5 text-green-600">
                                          <span className="text-[10px] font-bold uppercase tracking-tighter">
                                            Success
                                          </span>
                                          <CheckCircle size={18} />
                                        </div>
                                      ) : (
                                        <div className="flex items-center justify-end gap-1.5 text-red-500">
                                          <span className="text-[10px] font-bold uppercase tracking-tighter">
                                            Error
                                          </span>
                                          <AlertCircle size={18} />
                                        </div>
                                      )}
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
        )}
      </div>
    </div>
  );
}

export default App;
