MyList = new ReactiveList('a', 'b', 'c');

Template.list.list = function () {
    return MyList;
};

Template.list.events({
    'click #list-reverse': function(event) {
        event.preventDefault();
        MyList.reverse();
    },
    'click #list-add': function(event) {
        event.preventDefault();
        MyList.push((new Date()).toLocaleTimeString());
    },
    'click #list-remove': function(event) {
        event.preventDefault();
        MyList.pop();
    },
    'click #list-sort': function(event) {
        event.preventDefault();
        MyList.sort();
    }
});