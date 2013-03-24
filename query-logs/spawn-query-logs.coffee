#!/usr/bin/env coffee

# Prereqs for `npm install`
# --------------
getopt = require 'node-getopt'
spawn_minion = require 'spawn-minion'
buffered_reader = require 'buffered-reader'
buffered_writer = require 'buffered-writer'
DataReader = buffered_reader.DataReader

# Cmdline options
# ----------------
# Required: `-f` or `--files`
# Optional: `-o' or `--output`
optcfg = new getopt([
  ['f' , 'files=+','Input file'],
  ['o' , 'output=','Output to file'],
  ['h' , 'help'],
]).bindHelp()
opts = optcfg.parse(process.argv.slice(2))


# getResult(line)
# ---------------
# input
#
# - line of text from a .result file
#
# output
# returns an Array from splitting input by \t
getResult = (line) ->
	return unless line
	line.replace(/\n$/,'').split /\t/

# report(res,opt_fh)
# ------------------
# write an object to optional filehandle, opt_fh, or console.log
# object is sorted descending by value, then ascending by key when values match
#
# input
#
# - res = object to iterate
# - opt_fh = optional opened file, prints to console.log if not passed in
#
# output
# returns undefined
# 
report = (res,opt_fh) ->
   kys = (k for k of res)
   kys.sort((a,b) ->
      diff = res[b] - res[a]
      if diff is 0
         return a < b
      return diff
   )
   if opt_fh
      for k in kys
         opt_fh.write "#{k}\t#{res[k]}\n"
   else
      for k in kys
         console.log "#{k}\t#{res[k]}\n"
   opt_fh.close() if opt_fh


# gatherResults(files,results_fh)
# -------------------------------
# Combine *.results files, adding values together when same key found in multiple files

#
# input
#
# - res = Array of filenames to prepend '.results' to and read
# - opt_fh = optional opened file, prints to console.log if not passed in
#
# output
# returns undefined
gatherResults = (files,results_fh) ->
	data = {}
	filesToWatch = {}
	filesToWatch[file]=1 for file in files
	for file in files
		do(file) =>
			new DataReader(file + '.results', encoding: 'utf8')
				.on('error', (error) -> console.log error)
				.on('line', (line, nextByteOffset) ->
					[col1,col2,n] = getResult line
					unless col1 and col2 and n
						# handles 2 col, where most lines are 3 col
						if (not n) and /^\d+$/.test(""+col2)
							n = col2
							col2 = ''
					k = "#{col1}\t#{col2}"
					data[ k ] = (if data[k] then (data[k] + parseInt(n)) else parseInt(n))
				)
				.on('end', () ->
					delete filesToWatch[file]
					if (key for key, value of filesToWatch).length is 0
						report data,results_fh
				)
				.read()

# Start Main
#----------
files = opts.options.files;
outputfile = opts.options.output ? 'spawn.results'
results_fh = buffered_writer.open outputfile
results_fh.on 'error', (error) -> console.log "results error: #{error}"

# use spawn_minion to spawn a `minion-query-logs.coffee` process per `-f` file passed in
sp = new spawn_minion()
sp.addJob(['./minion-query-logs.coffee',file]) for file in files
# need this because spawn_minion defaults to 'node'
sp.setChildProcessName('coffee')
.start()
.causalty((e) -> console.log("error", e.toString()))
.conquered((e2) ->
	gatherResults files,results_fh)

