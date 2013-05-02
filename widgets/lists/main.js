/**
 * #Lists
 *
 * In Hull, a list can contain any number of objects of any type. Lists can be heterogeneous, that is to say a list can contain achievements, people or comments altogether.
 *
 * ## Examples
 *
 * <div data-hull-widget="lists@hull" data-hull-id="me"></div>
 *     
 * ## Options
 *
 * `id`: The id of the owner whose lists you want
 *
 * ## Templates
 *
 * * `lists`: How the contents of the list should be displayed
 *
 * ## Datasources
 *
 * `lists`: Contains the contents of the list for which the widget has been instantiated
 *
 * ## Events:
 *
 * `form submit`: When the user submits the form included in the template, a list is created with the properties defined in the forms
 *
 * @TODO Don't use DOM events, use widget acions instead
 */
define({
  type: "Hull",
  templates: ['lists'],
  events: { 'submit form' : 'createList' },

  //SALE _ PABO
  //Idealement : Refresh automatique quand une datasource change
  refreshEvents: ['model.hull.me.change', 'model.hull.me.lists.change'],

  datasources: {
    lists: ":id/lists"
  },

  beforeRender: function(data){
    if(data.lists){
      _.each(data.lists,function(list){
        _.each(list.items,function(item){
          item.name = item.name||item.uid
        });
      });
    }

    return data;
  },
  
  createList: function(e) {
    e.preventDefault();
    var self = this, inputs = {};
    this.sandbox.dom.find('input', this.$el).each(function(c, input) {
      if (input.getAttribute('type') === 'text') {
        inputs[input.getAttribute('name')] = input.value;
      }
    });
    this.api(this.id + '/lists', 'post', inputs).then(function() { self.render(); });
  }

});
