/**
 *
 *
 */

Hull.component({

  type: 'Hull',

  require:["//dc8na2hxrj29i.cloudfront.net/code/keen-2.1.0-min.js"],

  templates: ['main'],

  options:{
    eventCollection:'Loaded a Page',
    analysisType:'count',
    // targetProperty:'value',
    timeFrame: 'this_week',
    interval: 'hourly',
    timezone:'3600'
  },
  
  initialize: function(){
  },

  beforeRender: function(data){
  },

  afterRender: function(data){
    var self = this;
    Keen.onChartsReady(function() {
      var series = new Keen.Series(data.options.eventCollection, {
        analysisType: data.options.analysisType,
        timeframe: data.options.timeFrame,
        interval: data.options.interval,
        targetProperty: data.options.targetProperty
      });
      series.draw(self.$el[0]);
    });
  },

  actions: {
  }

});
