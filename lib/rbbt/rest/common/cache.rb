
require 'rbbt/rest/common/users'

module RbbtRESTHelpers

  MEMORY_CACHE = {}

  def old_cache(path, check)
    return false if check.nil? or check.empty?
    return false if not File.exists? path
    check = [check] unless Array === check
    return check.select{|file| not File.exists?(file) or File.mtime(file) > File.mtime(path)}.any?
  end

  def cache(name, params = {}, &block)
    return yield if name.nil? or cache_type.nil? or cache_type == :none

    check = [params[:_template_file]].compact
    check += consume_parameter(:_cache_check, params) || []
    check.flatten!

    name = name  + "_" + Misc.hash2md5(params)
    
    path = File.join(settings.cache_dir, "sinatra", name)
    task = Task.setup(:name => "Sinatra cache", :result_type => :string, &block)

    step = Step.new(path, task, nil, nil, self)

    self.instance_variable_set("@step", step)

    if @fragment
      fragment_file = step.file(@fragment)
      if File.exists?(fragment_file)
        ddd "Loading fragment: #{ fragment_file }"
        halt 200, File.read(fragment_file)
      else
        halt 202, "Fragment not ready"
      end
    end

    step.clean if old_cache(path, check) or update == :reload

    step.fork unless step.started?

    step.join if cache_type == :synchronous or cache_type == :sync

    if update == :reload
      url = request.url
      url = remove_GET_param(url, :_update)
      redirect to(url)
    end

    begin
      case step.status
      when :error
        error_for step
      when :done
        step.load
      else
        wait_on step
      end
    rescue Retry
      retry
    end
  end
end

