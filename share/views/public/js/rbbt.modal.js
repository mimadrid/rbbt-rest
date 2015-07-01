rbbt.modal = {}
rbbt.modal.element = document.getElementById('modal')

rbbt.modal.vm = (function(){
  var vm = {}
  vm.init = function(){
    vm.visible = m.prop(false)
    vm.content = m.prop("")
    vm.title = m.prop("")
  }

  return vm
}())

rbbt.modal.controller = function(){
  var controller = rbbt.modal.controller
  var vm = rbbt.modal.vm
  vm.init()

  controller._set = function(content, title){
    vm.content(content)
    if (undefined !== title)
      vm.title(title)
    vm.visible(true)
  }

  controller.show = function(content, title){
    controller._set(content, title)
    $(rbbt.modal.element).addClass('active')
    m.redraw()
  }

  controller.error = function(content, title){
    controller._set(content, title)
    $(rbbt.modal.element).addClass('active')
    $(rbbt.modal.element).addClass('error')
    m.redraw()
  }


  controller.show_url = function(url, title){
    if (typeof url == 'string') params = {url: url, method: 'GET',deserialize: function(v){return v}}
    else params = url
    return rbbt.insist_request(params).then(function(content){
      controller.show(content, title)
    })
  }

  controller.close = function(){
    vm.visible(false)
    $(rbbt.modal.element).removeClass('error')
    $(rbbt.modal.element).removeClass('active')
    m.redraw()
  }

  return controller
}

rbbt.modal.view = function(controller){
  if (rbbt.modal.vm.visible()){
    var title
    if ('object' == typeof rbbt.modal.vm.title()) title = rbbt.modal.vm.title()
    else title = m.trust(rbbt.modal.vm.title())

    var content
    if ('object' == typeof rbbt.modal.vm.content()) content = rbbt.modal.vm.content()
    else content = m.trust(rbbt.modal.vm.content())


    var header = [title, rbbt.mview.ibutton({onclick: rbbt.modal.controller.close, class:'small close', style: 'margin-top: -4px'}, m('i.icon.close'))]
    var modal_content = [m('.header', header), m('.content', content)]
    return modal_content
  }else{
    return ""
  }
}

if (rbbt.modal.element) m.module(rbbt.modal.element, rbbt.modal)
