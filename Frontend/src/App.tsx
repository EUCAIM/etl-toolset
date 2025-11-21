import React, { useState, useEffect } from 'react';
import { RefreshCw, Database, AlertCircle, CheckCircle, Clock, FileText } from 'lucide-react';


const backendIp = import.meta.env.VITE_BACKEND_IP;


interface Job {
  id: string;
  filename: string;
  step: string;
}

function App() {
  const [jobs, setJobs] = useState<Job[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null);

  const fetchJobs = async () => {
    try {
      setLoading(true);
      setError(null);
      
      const response = await fetch("http://" + backendIp + ":3000/jobs");
      
      if (!response.ok) {
        throw new Error(`Failed to fetch jobs: ${response.status} ${response.statusText}`);
      }
      
      const data = await response.json();
      setJobs(data);
      setLastUpdated(new Date());
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An unknown error occurred');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchJobs();
  }, []);

  const getStepIcon = (step: string) => {
    const stepLower = step.toLowerCase();
    if (stepLower.includes('complete') || stepLower.includes('done') || stepLower.includes('finished')) {
      return <CheckCircle className="w-4 h-4 text-green-500" />;
    }
    if (stepLower.includes('processing') || stepLower.includes('running') || stepLower.includes('progress')) {
      return <Clock className="w-4 h-4 text-blue-500 animate-spin" />;
    }
    if (stepLower.includes('error') || stepLower.includes('failed') || stepLower.includes('fail')) {
      return <AlertCircle className="w-4 h-4 text-red-500" />;
    }
    return <FileText className="w-4 h-4 text-gray-500" />;
  };

  const getStepBadgeColor = (step: string) => {
    const stepLower = step.toLowerCase();
    if (stepLower.includes('complete') || stepLower.includes('done') || stepLower.includes('finished')) {
      return 'bg-green-100 text-green-800 border-green-200';
    }
    if (stepLower.includes('processing') || stepLower.includes('running') || stepLower.includes('progress')) {
      return 'bg-blue-100 text-blue-800 border-blue-200';
    }
    if (stepLower.includes('error') || stepLower.includes('failed') || stepLower.includes('fail')) {
      return 'bg-red-100 text-red-800 border-red-200';
    }
    return 'bg-gray-100 text-gray-800 border-gray-200';
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-blue-50">
      <div className="container mx-auto px-4 py-8">
        {/* Header */}
        <div className="mb-8">
          <div className="flex items-center gap-3 mb-4">
            <div className="p-2 bg-blue-600 rounded-lg">
              <Database className="w-6 h-6 text-white" />
            </div>
            <div>
              <h1 className="text-3xl font-bold text-gray-900">ETL Jobs Dashboard</h1>
            </div>
          </div>
          
          {/* Stats and Actions */}
          <div className="flex flex-col sm:flex-row gap-4 items-start sm:items-center justify-between">
            <div className="flex gap-4">
              <div className="bg-white px-4 py-2 rounded-lg shadow-sm border">
                <span className="text-sm font-medium text-gray-600">Total Jobs</span>
                <p className="text-2xl font-bold text-gray-900">{jobs.length}</p>
              </div>
              {lastUpdated && (
                <div className="bg-white px-4 py-2 rounded-lg shadow-sm border">
                  <span className="text-sm font-medium text-gray-600">Last Updated</span>
                  <p className="text-sm text-gray-900">{lastUpdated.toLocaleTimeString()}</p>
                </div>
              )}
            </div>
            
            <button
              onClick={fetchJobs}
              disabled={loading}
              className="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200"
            >
              <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
              Refresh
            </button>
          </div>
        </div>

        {/* Main Content */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
          {error && (
            <div className="p-6 bg-red-50 border-b border-red-200">
              <div className="flex items-center gap-3">
                <AlertCircle className="w-5 h-5 text-red-500" />
                <div>
                  <h3 className="font-medium text-red-900">Error Loading Jobs</h3>
                  <p className="text-sm text-red-700">{error}</p>
                </div>
              </div>
            </div>
          )}

          {loading ? (
            <div className="p-12 text-center">
              <div className="inline-flex items-center gap-3 text-gray-600">
                <RefreshCw className="w-5 h-5 animate-spin" />
                <span className="text-lg">Loading jobs...</span>
              </div>
            </div>
          ) : jobs.length === 0 ? (
            <div className="p-12 text-center">
              <Database className="w-12 h-12 text-gray-400 mx-auto mb-4" />
              <h3 className="text-lg font-medium text-gray-900 mb-2">No jobs found</h3>
              <p className="text-gray-600">There are no jobs to display at the moment.</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="bg-gray-50 border-b border-gray-200">
                    <th className="text-left py-4 px-6 font-semibold text-gray-900">Job ID</th>
                    <th className="text-left py-4 px-6 font-semibold text-gray-900">Filename</th>
                    <th className="text-left py-4 px-6 font-semibold text-gray-900">Step</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-200">
                  {jobs.map((job, index) => (
                    <tr 
                      key={job.id} 
                      className={`hover:bg-gray-50 transition-colors duration-150 ${
                        index % 2 === 0 ? 'bg-white' : 'bg-gray-50/50'
                      }`}
                    >
                      <td className="py-4 px-6">
                        <div className="font-mono text-sm text-gray-900 bg-gray-100 px-2 py-1 rounded inline-block">
                          {job.id}
                        </div>
                      </td>
                      <td className="py-4 px-6">
                        <div className="flex items-center gap-2">
                          <FileText className="w-4 h-4 text-gray-500" />
                          <span className="text-gray-900 font-medium">{job.filename}</span>
                        </div>
                      </td>
                      <td className="py-4 px-6">
                        <div className="flex items-center gap-2">
                          {getStepIcon(job.step)}
                          <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium border ${getStepBadgeColor(job.step)}`}>
                            {job.step}
                          </span>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>

        {/* Footer */}
        {jobs.length > 0 && (
          <div className="mt-6 text-center text-sm text-gray-500">
            Showing {jobs.length} job{jobs.length !== 1 ? 's' : ''}
          </div>
        )}
      </div>
    </div>
  );
}

export default App;