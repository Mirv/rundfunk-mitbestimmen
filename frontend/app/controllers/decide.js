import Ember from 'ember';

export default Ember.Controller.extend({
  session: Ember.inject.service('session'),
  intl: Ember.inject.service(),
  queryParams: ['q', 'medium', 'station'],
  q: null,
  medium: null,
  station: null,

  page: Ember.computed.alias("content.page"),
  perPage: Ember.computed.alias("content.perPage"),
  totalPages: Ember.computed.alias("content.totalPages"),

  actions: {
    searchAction(query){
      this.send('setQuery', query);
    },
    respond(broadcast){
      broadcast.get('selections.firstObject').save();
    },
    browse(step){
      console.log(`browse in decide controller: ${step}`);
      this.get('model').forEach((broadcast) => {
        let selection = broadcast.setDefaultResponse('neutral');
        selection.save();
      });
      this.set('page', step);
    }

  }
});

