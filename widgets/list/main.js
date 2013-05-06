/**
 * #Lists
 *
 * In Hull, a list can contain any number of objects of any type. Lists can be heterogeneous, that is to say a list can contain achievements, people or comments altogether.
 *
 * ## Options
 *
 * `id`: The id of the list
 *
 * ## Templates
 *
 * * `list`: How the contents of the list should be displayed
 *
 * ## Datasources
 *
 * `list`: Contains the contents of the list for which the widget has been instantiated
 *
 */
define({
  type: "Hull",
  templates: ['list'],

  //SALE _ PABO
  //Idealement : Refresh automatique quand une datasource change
  refreshEvents: ['model.hull.me.change', ':id'],

  datasources: {
    list: ":id"
  },

  beforeRender: function(data){
    if(data.list){
      _.each(data.list.items,function(item){
        item.name = item.name||item.uid
      });
    }
    return data;
  }
});
