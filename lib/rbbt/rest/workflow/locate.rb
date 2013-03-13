module WorkflowRESTHelpers
  attr_accessor :workflow_resources

  def self.workflow_resources
    @workflow_resources ||= [Rbbt.share.views.find(:lib)]
  end

  def workflow_resources
    [Rbbt.www.views.find(:lib)] + WorkflowRESTHelpers.workflow_resources
  end
 
  def locate_workflow_template_from_resource(resource, template, workflow = nil, task = nil)
    template += '.haml' unless template =~ /.+\..+/

    paths = []
    paths << resource[workflow][task][template] if task and workflow
    paths << resource[workflow][template] if workflow
    paths << resource[template]

    paths.each do |path|
      return path.find if path.exists?
    end 

    nil
  end   

  def locate_workflow_template(template, workflow = nil, task = nil)

    if workflow
      path = locate_workflow_template_from_resource(workflow.libdir.www.views.find, template, workflow, task)
      return path if path and path.exists?
    end

    workflow_resources.each do |resource|
      path = locate_workflow_template_from_resource(resource, template, workflow, task)
      return path if path and path.exists?
    end

    raise "Template not found: [#{ template }, #{workflow}, #{ task }]"
  end
end
