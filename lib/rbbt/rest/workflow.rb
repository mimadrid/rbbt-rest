require 'rbbt'
require 'rbbt/workflow'

require 'rbbt/rest/common/locate'
require 'rbbt/rest/common/misc'
require 'rbbt/rest/common/render'
require 'rbbt/rest/common/forms'
require 'rbbt/rest/common/users'

require 'rbbt/rest/workflow/locate'
require 'rbbt/rest/workflow/render'
require 'rbbt/rest/workflow/jobs'


require 'sinatra/base'
require 'json'

module Sinatra
  module RbbtRESTWorkflow
    WORKFLOWS = []


    def add_workflow_resource(workflow, priority_templates = false)
      views_dir = workflow.respond_to?(:libdir)? workflow.libdir.www.views.find(:lib) : nil
      if views_dir and views_dir.exists?
        Log.debug "Registering views for #{ workflow }: #{ views_dir.find } - priority #{priority_templates}"
        RbbtRESTMain.add_resource_path(views_dir, priority_templates)
      end
    end

    def add_workflow(workflow, add_resource = false)
      raise "Provided workflow is not of type Workflow" unless  Workflow === workflow 
      RbbtRESTWorkflow::WORKFLOWS.push workflow unless RbbtRESTWorkflow::WORKFLOWS.include? workflow

      Log.debug "Adding #{ workflow } to REST server" 

      add_workflow_resource(workflow, add_resource == :priority) if add_resource
      workflow.documentation


      self.instance_eval workflow.libdir.lib['sinatra.rb'].read, workflow.libdir.lib['sinatra.rb'].find if workflow.respond_to?(:libdir) and  File.exists? workflow.libdir.lib['sinatra.rb']

      get "/#{workflow.to_s}" do
        case format
        when :html
          workflow_render('tasks', workflow, nil, @clean_params)
        when :json
          content_type "application/json"

          @can_stream = ENV["RBBT_WORKFLOW_TASK_STREAM"]  == 'true'
          {:stream => workflow.stream_exports, :exec => workflow.exec_exports, :synchronous => workflow.synchronous_exports, :asynchronous => workflow.asynchronous_exports, :can_stream => !!@can_stream}.to_json
        else
          raise "Unsupported format specified: #{ format }"
        end
      end

      get "/#{workflow.to_s}/documentation" do
        case format
        when :html
          workflow_render('tasks', workflow)
        when :json
          content_type "application/json"
          workflow.documentation.to_json
        else
          raise "Unsupported format specified: #{ format }"
        end
      end

      get "/#{workflow.to_s}/:task/info" do
        task     = consume_parameter(:task)

        raise Workflow::TaskNotFoundException.new workflow, task unless workflow.tasks.include? task.to_sym

        case format
        when :html
          workflow_render('task_info', workflow, nil, :cache => false )
        when :json
          content_type "application/json"
          workflow.task_info(task.to_sym).to_json
        else
          raise "Unsupported format specified: #{ format }"
        end
      end

      get "/#{workflow.to_s}/:task/dependencies" do
        task     = consume_parameter(:task)

        raise Workflow::TaskNotFoundException.new workflow, task unless workflow.tasks.include? task.to_sym

        case format
        when :html
          workflow_render('task_dependencies', workflow)
        when :json
          content_type "application/json"
          workflow.task_dependencies[task.to_sym].to_json
        else
          raise "Unsupported format specified: #{ format }"
        end
      end

      get "/#{workflow.to_s}/description" do
        halt 200, workflow.documentation[:description] || ""
      end


      get "/#{workflow.to_s}/:task" do
        task     = consume_parameter(:task)
        jobname  = consume_parameter(:jobname)

        raise Workflow::TaskNotFoundException.new workflow, task unless workflow.tasks.include? task.to_sym

        execution_type = execution_type(workflow, task)

        task_parameters = consume_task_parameters(workflow, task, params)
        
        task_parameters[:jobname] = jobname

        if complete_input_set(workflow, task, task_parameters) or format != :html 
          issue_job(workflow, task, jobname, task_parameters)
        else
          workflow_render('form', workflow, task, task_parameters)
        end
      end

      post "/#{workflow.to_s}/:task" do
        task = consume_parameter(:task)
        jobname  = consume_parameter(:jobname)

        raise Workflow::TaskNotFoundException.new workflow, task unless workflow.tasks.include? task.to_sym

        execution_type = execution_type(workflow, task)

        task_parameters = consume_task_parameters(workflow, task, params)

        issue_job(workflow, task, jobname, task_parameters)
      end

      get "/#{workflow.to_s}/:task/:job" do
        task = consume_parameter(:task)
        job  = consume_parameter(:job)

        raise Workflow::TaskNotFoundException.new workflow, task unless workflow.tasks.include? task.to_sym

        execution_type = execution_type(workflow, task)

        job = workflow.load_id(File.join(task, job))

        abort_job(workflow, job) and halt 200 if update.to_s == "abort"
        clean_job(workflow, job) and halt 200 if update.to_s == "clean"
        recursive_clean_job(workflow, job) and halt 200 if update.to_s == "recursive_clean"

        begin
          started = job.started?
          done = job.done?
          error = job.error? || job.aborted?

          if done
            show_result job, workflow, task, params
          else
            if started
              exec_type = execution_type(workflow, task) 
              case
              when error
                error_for job
              when (exec_type == :asynchronous or exec_type == :async)
                case @format.to_s
                when 'json', 'raw', 'binary'
                  halt 202
                else
                  wait_on job
                end
              else
                job.join
                raise RbbtRESTHelpers::Retry
              end
            else
              halt 404, "Job not found: #{job.status}"
            end
          end
        rescue RbbtRESTHelpers::Retry
          retry
        end
      end

      get "/#{workflow.to_s}/:task/:job/info" do
        task = consume_parameter(:task)
        job  = consume_parameter(:job)

        raise Workflow::TaskNotFoundException.new workflow, task unless workflow.tasks.include? task.to_sym

        execution_type = execution_type(workflow, task)

        job = workflow.load_id(File.join(task, job))

        raise RbbtException.new "Job not found: #{job.path}" unless job.started?

        begin
          check_step job unless job.done?
        rescue Aborted
        end

        case format
        when :html
          workflow_render('job_info', workflow, task, :info => job.info)
        when :json
          content_type "application/json"
          info_json = {}
          job.info.each do |k,v|
            info_json[k] = case v.to_s
                           when "NaN"
                             "NaN"
                           when "Infinity"
                             "Infinity"
                           else
                             v
                           end
          end
          halt 200, info_json.to_json
        else
          raise "Unsupported format specified: #{ format }"
        end
      end

      get "/#{workflow.to_s}/:task/:job/files" do
        task = consume_parameter(:task)
        job  = consume_parameter(:job)

        raise Workflow::TaskNotFoundException.new workflow, task unless workflow.tasks.include? task.to_sym

        execution_type = execution_type(workflow, task)

        job = workflow.load_id(File.join(task, job))

        case format
        when :html
          workflow_render('job_files', workflow, task, :info => job.info)
        when :json
          content_type "application/json"
          job.files.to_json
        else
          raise "Unsupported format specified: #{ format }"
        end
      end

      get "/#{workflow.to_s}/:task/:job/file/*" do
        task = consume_parameter(:task)
        job  = consume_parameter(:job)
        filename = params[:splat].first

        raise Workflow::TaskNotFoundException.new workflow, task unless workflow.tasks.include? task.to_sym

        execution_type = execution_type(workflow, task)

        job = workflow.load_id(File.join(task, job))

        require 'mimemagic'
        path = job.file(filename)
        mime = nil
        Open.open(path) do |io|
          begin
            mime = MimeMagic.by_path(io) 
            if mime.nil?
              io.rewind
              mime = MimeMagic.by_magic(io) 
            end
            if mime.nil?
              io.rewind
              mime = "text/tab-separated-values" if io.gets =~ /^#/ and io.gets.include? "\t"
            end
          rescue Exception
            Log.exception $!
          end
        end
        content_type mime if mime
        send_file path
      end

      delete "/#{workflow.to_s}/:task/:job" do
        task = consume_parameter(:task)
        job  = consume_parameter(:job)
        job  = workflow.load_id(File.join(task, job))

        raise Workflow::TaskNotFoundException.new workflow, task unless workflow.tasks.include? task.to_sym

        clean_job(workflow, job)
      end
    end

    def self.registered(base)
      base.module_eval do
        helpers WorkflowRESTHelpers

        if ENV["RBBT_WORKFLOW_TASK_STREAM"] == 'true'
          require 'rbbt/rest/workflow/stream_task'
          Log.info "Preparing server for streaming workflow tasks"
          use StreamWorkflowTask if not @can_stream
          @can_stream = true
        else
          @can_stream = false
        end
      end
    end
  end
end

