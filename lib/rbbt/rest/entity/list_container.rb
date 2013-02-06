class ListContainer
  attr_accessor :lists
  def initialize
    @lists = []
  end

  def add(list_id, list, text = nil)
    if list and list.any?
      @lists << [list_id, list, text]
    end
  end

end

module EntityRESTHelpers
  def list_container_render(container)
    partial_render('entity_partials/list_container', :container => container)
  end
end
