Package.describe({
  summary: "Reactive Extra package, providing some reactive classes."
});

var path = Npm.require("path");
Package.on_use(function(api) {
  // Required packages
  api.use(["deps", "ejson", "underscore"], ["client", "server"]);
  api.use(["templating", "handlebars"], ["client"]);

  // Server and client side code
  api.add_files([
    path.join("lib","reactive-object.js"),
    path.join("lib","reactive-dictionary.js"),
    path.join("lib","reactive-array.js"),
    path.join("lib","reactive-list.js")
  ], ["client", "server"]);

  // Client side code
  api.add_files([
    path.join("lib","handlebars-list.js")
  ], ["client"]);
});

Package.on_test(function(api) {
  // Required packages
  api.use(["tinytest", "reactive-extra"], ["client", "server"]);

  // Server and client side tests
  api.add_files([
    path.join("lib","reactive-dictionary-test.js"),
    path.join("lib","reactive-object-test.js"),
    path.join("lib","reactive-array-test.js"),
    path.join("lib","reactive-list-test.js")
  ], ["client", "server"]);
});
