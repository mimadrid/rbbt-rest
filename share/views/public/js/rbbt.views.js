rbbt.mview = {}

rbbt.mview.plot = function(content, title, caption){
  var plot 

  if (undefined === title){
    plot = m('figure.ui.segment', m('.header', 'No figure to display'))
  }else{
    if (title == 'loading'){
      plot = m('figure.ui.segment.loading', 'loading figure')
    }else{
      var elems = []
      var img_title = title

      if (! img_title) img_title = 'image'
      else img_title = img_title.replace(': ', ' ')
        
      var img_filename = img_title + '.svg'
      var download_func = function(){
        var blob = new Blob([content], {type: "image/svg+xml;charset=utf-8"});
        return saveAs(blob, img_filename);
      }
      var download = m('.download.ui.labeled.icon.button',{onclick: download_func}, [m('i.icon.download'), "Download"])
      if (title) elems.push(m('.ui.header', title))
      elems.push(m('.content.svg', m.trust(content)))
      if (caption) elems.push(m('figcaption', m.trust(caption)))
      if (content) elems.push(download)

      plot = m('figure.ui.segment', elems)
    }

  }

  return plot
}

rbbt.mview.button = function(options,args){
  return m('.ui.button', options, args)
}

rbbt.mview.ibutton = function(options,args){
  return m('.ui.icon.button', options, args)
}

rbbt.mview.dropdown = function(name, options){
 return m('.ui.dropdown.item', [m('i.icon.dropdown'), name, m('.menu', options)])
}
