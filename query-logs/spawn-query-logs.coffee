#!/usr/bin/env coffee

spawn_minion = require 'spawn-minion'
buffered_reader = require 'buffered-reader'
buffered_writer = require 'buffered-writer'
BinaryReader = buffered_reader.BinaryReader
DataReader = buffered_reader.DataReader

close = (binaryReader, error) ->
   console.log error if error
   binaryReader.close (error) ->
      console.log error if error


files = {}

results_fh = buffered_writer.open 'spawn.results'
results_fh.on 'error', (error) -> console.log "results error: #{error}"

getResult = (line) ->
	return unless line
	line.replace(/\n$/,'').split /\t/

report = (res,opt_fh) ->
   #console.log "in report"
   #console.log "report key length #{(key for key, value of res).length}"
   kys = (k for k of res)
   kys.sort((a,b) -> return res[b] - res[a] )
   #console.log "kys #{kys}"
   if opt_fh
      for k in kys
         #console.log "1 kys #{k}\t#{res[k]}\n"
         opt_fh.write "#{k}\t#{res[k]}\n"
   else
      for k in kys
         #console.log "2 kys #{k}\t#{res[k]}\n"
         console.log "#{k}\t#{res[k]}\n"
   #console.log "leaving report"
   opt_fh.close() if opt_fh


gatherResults = (myfiles,results_fh) ->
	data = {}
	for file of myfiles
		do(file) =>
			console.log "handling file #{file}"
			new DataReader(file + '.results', encoding: 'utf8')
				.on('error', (error) -> console.log error)
				.on('line', (line, nextByteOffset) ->
					[col1,col2,n] = getResult line
					return unless col1 and col2 and n
					k = "#{col1}\t#{col2}"
					data[ k ] = (if data[k] then (data[k] + parseInt(n)) else parseInt(n))
					#console.log "data[ k ] #{data[ k ]}"
				)
				.on('end', () ->
					#
					# at the end of each parsed file, remove that filename from the files Object
					# so that when Object has no keys, run the function, report, that writes out
					# the combined results to a file called 'results'
					#
					delete myfiles[file]
					if (key for key, value of myfiles).length is 0
						report data,results_fh
				)
				.read()

files = {}
(files[file] = 1 for file in process.argv[2..])

sp = new spawn_minion()

for file of files
	sp.addJob(['./minion-query-logs.coffee',file])

sp.setChildProcessName('coffee')
.start()
.causalty((e) -> console.log("error", e.toString()))
.conquered((e2) ->
	console.log "conquered #{e2}" if e2
	gatherResults files,results_fh)

