/**
 *
 *
 */

Hull.component({

  type: 'Hull',

  require:["//dc8na2hxrj29i.cloudfront.net/code/keen-2.1.0-min.js"],

  templates: ['main'],

  options:{
    eventCollection:'testing',
    analysisType:'sum',
    targetProperty:'value',
    timeFrame: 'this_week',
    interval: 'daily',
    timezone:'3600'
  },
  
  initialize: function(){
  },

  beforeRender: function(data){
  },

  afterRender: function(data){
    var self = this;
    Keen.onChartsReady(function() {
      var metric = new Keen.Metric(data.options.eventCollection, {
        analysisType: data.options.analysisType,
        targetProperty: data.options.targetProperty
      });
      metric.draw(self.$el[0]);
    });
  },

  actions: {
  }

});
