var reload_seconds_for_try = {0: 1, 1: 1, 2: 2, 3: 2, 4: 3, 5: 7, 6: 7, 7: 7, 8: 7, 9: 7, 10: 30, 11: 30, 12: 60, 13: 120, 14: 120, 15: 120, 16: "STOP"}

function reload_time(object){
  var tries = object.attr('reload-attempts');
  if (undefined === tries){ tries = 0 };

  if (typeof tries == 'string' || tries instanceof String){ tries = parseInt(tries) }


  object.attr('reload-attempts', tries + 1);
  return reload_seconds_for_try[tries];
}

function replace_object(object, href, embedd, complete){
  if (embedd === undefined){ embedd = false; }
  if (complete === undefined){ complete = []; }


  $.ajax({
    url : href,
    cache: false,
    beforeSend: function(){ object.addClass("reloading") },
    complete: complete,
    error: function( req, text, error ) {
      href = remove_parameter(href, '_update');
      href = remove_parameter(href, '_');
      object.removeClass("reloading").addClass("error").css('height', 0).html(error).css('height', 'auto').attr('target-href', href);
    },
    success: function( data, stat, req ) {
      object.removeClass('error');
      if (req.status == 202){
        object.addClass("reloading");
        href = remove_parameter(href, '_update');
        href = remove_parameter(href, '_');
        var reload_seconds = reload_time(object);

        if (reload_seconds == "STOP"){
          object.removeClass("reloading").addClass("error").html("Maximum number or retries reached").attr('reload-attempts', 0);
        }else{
          window.setTimeout(function(){replace_object(object, href, embedd)}, reload_seconds * 1000);
        }
      }else{
        object.removeClass("reloading").attr('reload-attempts', 0);
        if (embedd){
          href = remove_parameter(href, '_update');
          href = remove_parameter(href, '_');
          object.html(data).addClass("embedded").attr('target-href', href);
          capture_embedded_form(object);
          update_dom();
        }else{
          object.replaceWith(data);
          update_dom();
        }
      }
    }
  })
}

function replace_link(link){
  var href = $(link).attr('href');

  replace_object(link, href);
}

function update_embedded(object){
  var href = object.attr('target-href');
  href = add_parameters(href, '_update=reload')
  href = add_parameters(href, '_=' + Math.random().toString());
  replace_object(object, href, true);
}


function capture_embedded_form(object){

  object.find('form').submit(function(){ 
    var form = $(this);
    var embedded = object;

    var params = "";

    form.find('input').not('[type=submit]').not('[type=radio]').each(function(){
      var input = $(this)
      if (params.length > 0){ params += '&'}
      params += input.attr('name') + "=" + input.val();
    })

    form.find('input[type=radio]:checked').each(function(){
      var input = $(this)
      if (params.length > 0){ params += '&'}
      params += input.attr('name') + "=" + input.val();
    })

    form.find('select').not('[type=submit]').each(function(){
      var select = $(this)
      var option = select.find('option:selected');
      if (params.length > 0){ params += '&'}
      params += select.attr('name') + "=" + option.val();
    })

    form.find('textarea').each(function(){
      var input = $(this)
      if (params.length > 0){ params += '&'}
      params += input.attr('name') + "=" + escape(input.val());
    })

    params = params
    
    var url = embedded.attr('target-href');

    if (url.indexOf('?') == -1){
      url = url + '?' + params;
    }else{
      url = url.replace(/\?.*/, '?' + params);
    }

    embedded.attr('target-href', url)

    update_embedded(embedded);

    return false;
  })
}

