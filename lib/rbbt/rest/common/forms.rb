require 'rbbt/rest/common/misc'

module RbbtRESTHelpers

  def input_label(id, description, default = nil, options = {})
    text = description
    text += html_tag('span', " (default: " << default.to_s << ")", :class => 'input_default') unless default.nil?
    label_id = id.nil? ? nil : 'label_for__' << id
    html_tag('label', text, {:id => label_id, :for => id}.merge(options))
  end

  def file_or_text_area(id, name, value)
    html_tag("input", nil, :type => "file", :id => id +  "__" + "param_file", :name => name.to_s + "__" + "param_file") + 
    html_tag("span", "or use the text area bellow", :class => "file_or_text_area") + 
    html_tag("textarea", value || "" , :name => name, :id => id )
  end

  def form_input(name, type, default = nil, current = nil, description = nil, id = nil, extra = {})
    if description.nil?
      description = name.to_s
    else
      description = name.to_s + ": " + description
    end

    html_options = consume_parameter(:html_options, extra ) || {}

    case type
    when :boolean
      current = param2boolean(current) unless current.nil?
      default = param2boolean(default) unless default.nil?

      check_true = current.nil? ? default : current
      check_true = false if check_true.nil?
      check_false = ! check_true
      
      if id
        false_id = id + '__' << 'false'
        true_id = id + '__' << 'true'
      else
        false_id = nil
        true_id = nil
      end

      input_label(id, description, default) +
        html_tag("input", nil, :type => :hidden, :name => name.to_s + "_checkbox_false", :value => "false") +
        html_tag("input", nil, :type => :checkbox, :checked => check_true, :name => name, :value => "true", :id => id)

    when :string, :float, :integer
      value = current.nil?  ? default : current

      input_type = type == :string ? "text" : "number"
      step = case type
             when :string
               nil
             when :float
               "any"
             when :integer
               1
             end

      input_label(id, description, default) +
      html_tag("input", nil, html_options.merge(:type => input_type, :name => name, :value => value, :id => id, :step => step))

    when :tsv, :array, :text
      value = current.nil? ? default : current
      value = value * "\n" if Array === value

      input_label(id, description, default) +
      file_or_text_area(id, name, value)

    when :select
      value = current.nil? ? default : current


      allow_empty = consume_parameter :allow_empty, extra
      select_options = consume_parameter :select_options, extra
      

      if select_options 
        options = select_options.collect do |option|
          option, option_name = option if Array === option
          option_name = option if option_name.nil?
          html_tag('option', option_name, :value => option, :selected => option.to_s == value.to_s)
        end 
      else
        options = []
      end

      options.unshift html_tag('option', 'none', :value => 'none', :selected => value.to_s == 'none') if allow_empty

      input_label(id, description, default) +
        html_tag('select', options * "\n", html_options.merge(:name => name, :id => id, "attr-selected" => (value ? value.to_s : "")))
    else
      "<span> Unsupported input #{name} #{type} </span>"
    end
  end
end