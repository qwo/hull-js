Hull.widget('ractive', {
  datasources: {
    model: function () {
      return {
        p1: "xavier",
        p2: "cambar"
      };
    },
    temp: function () {
      return '';
    }
  },
  templates: ['main'],
  actions: {
    doSwitch: function () {
      console.log('switch', this._R)
      this.data.temp = this.data.model.p1;
      this.data.model.p1 = this.data.model.p2;
      this.data.model.p2 = this.data.temp;
    }
  }
});
