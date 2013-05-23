Package.describe({
  summary: "Reactive Extra package, providing some reactive classes."
});

Package.on_use(function(api) {
  api.use(["deps", "ejson", "underscore"], ["client", "server"]);
  return api.add_files(["lib/reactive-object.js", "lib/reactive-dictionary.js", "lib/reactive-array.js"], ["client", "server"]);
});

Package.on_test(function(api) {
  api.use(["tinytest", "deps", "ejson", "underscore", "reactive-extra"], ["client", "server"]);
  return api.add_files(["lib/reactive-dictionary-test.js", "lib/reactive-object-test.js", "lib/reactive-array-test.js"], ["client", "server"]);
});
