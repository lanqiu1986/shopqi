App.Views.Customer.Index.Search = Backbone.View.extend
  el: '#customer-filters'

  events:
    "keydown #customer-search_field": 'returnToSearch'
    "blur #customer-search_field": 'blurToSearch'

  initialize: ->
    self = this
    @model = App.customer_group
    @model.bind 'change', -> self.render()
    # 未输入内容时显示提示
    $("input[data-hint]").focus ->
      hint = $(this).attr('data-hint')
      $(this).css color: ''
      $(this).val('') if $(this).val() == hint
    .blur ->
      hint = $(this).attr('data-hint')
      $(this).val(hint).css(color: '#888') unless $(this).val()
    .blur()
    # 初始化过滤器
    $('#search-filter_primary').change()

  # 显示过滤器列表
  render: ->
    term_field = $('#customer-search_field')
    hint = term_field.attr('data-hint')
    value = term_field.val()
    unless !@model.get('term') and value is hint
      term_field.val @model.get('term')
      value = term_field.val()
      term_field.val(hint).css(color: '#888') unless value
    new App.Views.Customer.Index.Filter.Index model: @model
    this.search()

  returnToSearch: (e) ->
    this.blurToSearch() if e.keyCode == 13 # 回车

  blurToSearch: ->
    hint = $('#customer-search_field').attr('data-hint')
    value = $('#customer-search_field').val()
    if value isnt hint
      @model.set term: value

  # 查询
  search: ->
    [value, filters] = [@model.get('term'), @model.filters()]
    value = '' unless value
    params = q: value, f: _(filters).map (filter) -> "#{filter.condition}:#{filter.value}"
    $('#customer-search_msg').html('&nbsp;').show().css('background-image', 'url(/assets/spinner.gif)')
    $('#customer-search_overlay').show()
    $.get '/admin/customers/search', params, (data) ->
      App.customers.refresh(data)
      $('#customer-search_overlay').hide()
    model_id = @model.id
    # 左边分组 (查询条件为空时要重新激活所有顾客分组、在所有顾客分组中查询要激活当前查询)
    if @model.id == -1 and (value or !_.isEmpty(filters)) # 所有顾客 且 没有查询关键字和过滤条件
      model_id = 0
    # 更新分组条件
    customer_group = App.customer_groups.get model_id
    customer_group.set term: value, query: @model.get('query')
    if model_id isnt @model.id # id变化会触发左边分组切换
      @model.set id: model_id
