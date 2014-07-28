#
# Cakefile
#

{exec}  = require 'child_process'
pkgInfo = require './package'

task 'clean', 'Clean the directory by removing *.js', ->
  exec "rm -rf *.js", (error) -> if error then throw error

task 'compile', 'Compile individual files', ->
  exec "coffee -co ./ src", (error) ->
    if error then throw error

task 'test', 'Compile test specs', ->
  exec "coffee -co ./test test/src", (error) ->
    if error then throw error

task 'build', 'clean and build', ->
  invoke 'clean'
  invoke 'compile'
  invoke 'test'