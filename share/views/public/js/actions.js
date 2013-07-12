function load_action(link){
  var action_list_item = link.parent('li');
  var action_list = action_list_item.parent('ul');
  var action_controller = action_list.parents('.action_controller').first();
  var action_div = action_controller.next('.action_loader');
  var href = link.attr('href')

  setup_action_controls = function(jqXHR, textStatus){
    var action_div = action_controller.next('.action_loader');
    if (jqXHR.status == 202){
      action_controller.removeClass('active');

      var response = $(jqXHR.responseText)
      var stat = response.find('span.status').html()
      var message = response.find('ul.step_messages li:first').html()
      if (undefined === message){
        action_div.html("<span class='loading'>Loading [" + stat + "] ...</span>");
      }else{
        action_div.html("<span class='loading'>Loading [" + stat + ": " + message + "] ...</span>");
      }
    }else{ 
      action_controller.addClass('active'); 
      action_controller.find('ul.controls > li.reload').addClass('active');
    }

    var action_div = action_controller.next('.action_loader').first();
    if (action_div.find('> .action_card > .action_parameters').length > 0){
      action_controller.find('ul.controls > li.parameters').addClass('active');
    }else{
      action_controller.find('ul.controls > li.parameters').removeClass('active');
    }
  }

  if( ! action_div.hasClass('reloading') ) {
    action_div.removeClass('active');
    action_controller.find('ul.controls > li.reload').removeClass('active');
    action_controller.find('ul.controls > li.parameters').removeClass('active');
    action_list.find('li').removeClass('active');
    action_list_item.addClass('active');
    replace_object(action_div, href, true, setup_action_controls);

    return false
  }
}

function display_parameters(){
  var link = $(this);
  var action_controller = link.parents('.action_controller').first()
  var action_loader = action_controller.next('.action_loader').first();
  var action_parameters = action_loader.find('.action_parameters').first();
  var action_content = action_parameters.next('.action_content').first();

  action_parameters.toggleClass('active')
  action_content.toggleClass('shifted')

  $.scrollTo(action_controller, {axis:'y'})

  return false
}

function setup_action(){

  show_actions = function(){
    var link = $(this);
    var action_list_item = link.parent('li');
    var action_list = action_list_item.parent('ul.actions');
    action_list.addClass('select')

    return false
  };

  activate_action = function(){
    var link = $(this);
    load_action(link);

    var action_list_item = link.parent('li');
    var action_list = action_list_item.parent('ul.actions');
    action_list.removeClass('select')

    return false
  };

  reload_action = function(){
    var link = $(this);

    var action_list_item = link.parent('li');
    var action_list = action_list_item.parent('ul.controls');
    var action_controller = action_list.parent('.action_controller');
    var action_div = action_controller.next('.action_loader').first();

    if (action_div.attr('target-href') != undefined){
      update_embedded(action_div, true)
    }

    return false
  };

  var body = $('body');

  body.on('click', '.action_controller > ul.actions  li > a.entity_list_action', activate_action)
  body.on('click', '.action_controller > ul.actions  li > a.entity_action', activate_action)
  body.on('click', '.action_controller > ul.actions > li.select > a', show_actions)
  body.on('click', '.action_controller > ul.controls > li > a.reload_action', reload_action)
  body.on('click', '.action_controller > ul.controls > li.parameters > a', display_parameters)
}


