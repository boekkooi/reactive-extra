# # ** Cakefile **#
#
# * build - compiles src directory to lib directory
# * example - updates the example project
# * docs  - generates annotated documentation using docco

# Files to compile with coffeescript
files = [
  'src'
]

# ANSI Terminal Colors
bold = '\x1b[0;1m'
green = '\x1b[0;32m'
reset = '\x1b[0m'
red = '\x1b[0;31m'

# require the needed modules
fs = require 'fs'
path = require 'path'
{print} = require 'util'
{spawn, exec} = require 'child_process'
try wrench = require 'wrench' catch err
try which = require('which').sync catch err

if !wrench || !which && process.platform.match(/^win/)?
  console.log red + 'WARNING: Missing one of the following modules:'
  console.log '* wrench (npm install wrench)' if !wrench
  console.log '* which (npm install which)' if !which && process.platform.match(/^win/)?
  console.log reset

# Cakefile build output directory option
option '-o', '--output [DIR]', 'directory for compiled code'

# ## *build*
# Builds Source
task 'build', 'compile source', (options) ->
  dir  = options.output or 'lib'
  build dir

# ## *example*
# Update the example project
task 'example', 'compile source and copy it to example project', (options) ->
  build 'lib', () ->
    exampleDir = path.join('example', 'packages', 'reactive-extra')
    exampleLibDir = path.join(exampleDir, 'lib')

    wrench.rmdirSyncRecursive exampleDir
    wrench.mkdirSyncRecursive exampleLibDir
    wrench.copyDirSyncRecursive 'lib', exampleLibDir,
      forceDelete: true

    fs.writeFileSync path.join(exampleDir, 'package.js'), fs.readFileSync 'package.js'

    log 'Let\'s examine the example', green
    log 'why don\'t you test it?\ncd example\nmeteor test-packages reactive-extra', bold

# ## *docs*
# Generate Annotated Documentation
task 'docs', 'generate documentation', (options) ->
  dir  = options.output or 'docs'

  tmpDir = path.join dir, '.tmp'
  wrench.mkdirSyncRecursive tmpDir

  files = wrench.readdirSyncRecursive('src').filter (file) ->
    !fs.statSync( path.join('src', file) ).isDirectory();

  tmpFiles = files.map (file) ->
    path.join tmpDir, file.replace /[\/\\]/g, '_'

  for file of files
    fs.writeFileSync(tmpFiles[file], fs.readFileSync(path.join('src', files[file])));

  options = [ '-l', 'parallel', '-o', dir ]
  options = options.concat tmpFiles
  launch 'docco', options, () ->
    wrench.rmdirSyncRecursive tmpDir
    log "Get the api docs while there hot", green

# # Internal Functions

# ## *build*
build = (dir, callback) ->
  wrench.mkdirSyncRecursive dir

  options = ['-c', '-o', dir]
  options = options.concat files
  launch 'coffee', options, () ->
    if callback
      callback()
    else
      log 'Look mom I created a railroad', green

# ## *launch*
#
# **given** string as a cmd
# **and** optional array and option flags
# **and** optional callback
# **then** spawn cmd with options
# **and** pipe to process stdout and stderr respectively
# **and** on child process exit emit callback if set and status is 0
launch = (cmd, options=[], callback) ->
  cmd = which(cmd) if which
  app = spawn cmd, options
  app.stdout.pipe(process.stdout)
  app.stderr.pipe(process.stderr)
  app.on 'exit', (status) -> callback?() if status is 0

# ## *log*
#
# **given** string as a message
# **and** string as a color
# **and** optional string as an explanation
# **then** builds a statement and logs to console.
#
log = (message, color, explanation) ->
  console.log color + message + reset + ' ' + (explanation or '')