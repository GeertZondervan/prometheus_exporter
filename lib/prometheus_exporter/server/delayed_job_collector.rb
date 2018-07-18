module PrometheusExporter::Server
  class DelayedJobCollector < TypeCollector

    def type
      "delayed_job"
    end

    def collect(obj)
      ensure_delayed_job_metrics
      @delayed_job_duration_seconds.observe(obj["duration"], job_name: obj["name"])
      @delayed_jobs_total.observe(1, job_name: obj["name"])
      @delayed_failed_jobs_total.observe(1, job_name: obj["name"]) if !obj["success"]
      @delayed_job_max_attempts_reached.observe(1) if obj["attempts"] >= (Delayed::Worker.max_attempts)
      @delayed_job_duration_summary.observe(obj["duration"])
      @delayed_job_duration_summary.observe(obj["duration"], status: "success") if obj["success"]
      @delayed_job_duration_summary.observe(obj["duration"], status: "failed")  if !obj["success"]
      @delayed_job_attempts_summary.observe(obj["attempts"]) if obj["success"]
    end

    def metrics
      if @delayed_jobs_total
        [@delayed_job_duration_seconds, @delayed_jobs_total, @delayed_failed_jobs_total, @delayed_job_max_attempts_reached,
         @delayed_job_duration_summary, @delayed_job_attempts_summary]
      else
        []
      end
    end

    protected

    def ensure_delayed_job_metrics
      if !@delayed_jobs_total

        @delayed_job_duration_seconds =
        PrometheusExporter::Metric::Counter.new(
          "delayed_job_duration_seconds", "Total time spent on delayed jobs.")

        @delayed_jobs_total =
        PrometheusExporter::Metric::Counter.new(
          "delayed_jobs_total", "Total number of delayed jobs executed.")

        @delayed_failed_jobs_total =
        PrometheusExporter::Metric::Counter.new(
          "delayed_failed_jobs_total", "Total number failed delayed jobs executed.")


        @delayed_job_max_attempts_reached =
            PrometheusExporter::Metric::Counter.new(
                "delayed_job_max_attempts_reached", "Total number of delayed jobs that reached max attempts.")

        @delayed_job_duration_summary =
            PrometheusExporter::Metric::Summary.new("delayed_job_duration_summary",
                                                    "Summary of the time it takes for a job to execute.")

        @delayed_job_attempts_summary =
            PrometheusExporter::Metric::Summary.new("delayed_job_attempts_summary",
                                                    "Summary of the amount of attempts it takes delayed jobs to succeed.")
      end
    end
  end
end
