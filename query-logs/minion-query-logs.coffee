#!/usr/bin/env coffee

fs = require 'fs'

bwriter = require 'buffered-writer'
breader = require 'buffered-reader'
BinaryReader = breader.BinaryReader
DataReader = breader.DataReader

close = (binaryReader, error) ->
	console.log error if error
	binaryReader.close (error) ->
		console.log error if error

offset = 0

qr_subj_verb = /^\s*([^,]+)\s+(is\s+excluded)\s*$/
qr_subj_verb_obj = /^\s*([^,]+)\s+(equals|contains|is|blast)\s+([^,]+)\s*$/
qr_or_delimiter = /\s+or\s+/

finial = {}

queries_file = process.argv.join '--'
queries_file = queries_file.replace /[^0-9A-Za-z\.\,\-\_]/g,'--'

getQueryField = (data) ->
	return unless data
	return if data.indexOf('#') is 0
	[f0,f1,f2,f3,f4,f5,f6...] = data.split /[|]/
	query = f6.join ''

	## deal with query having | chars in it, ie entire field isn't quoted if it contains the delimiter character
	yes_no_idx = 0
	for f in f6
		break if /^\s*(?:yes|no)\s*$/.test f
		yes_no_idx++

	query = (f6[i] for i in [0..(yes_no_idx-2)]).join '|' unless yes_no_idx is 0
	return if /^\s*$/.test query
	query = query.replace /^\s+/,''
	query.replace /\s+$/,''


logQuery = (fh,data) ->
	return unless data
	fh.write data
	fh.write "\n" unless /\n$/.test data

 
parseQuery = (query) ->
	return unless query

	matches = []
	has_multiselect = 0
	#console.log "parseQuery: #{query}"
	## getting complex, we have multi-select queries, so that's multiple [subject|verb|[object]]+ separated by , or 'or'
	unless _find_subquery query,matches
		# split on ',' first, 'or' second and see if any subqueries fail a  subj|verb|(obj)* match
		for q in query.split(/,/)
			if -1 isnt q.search( qr_or_delimiter)
				submatches = []
				for submatch in q.split(qr_or_delimiter)
					_find_subquery submatch, submatches
				if submatches.length > 0
					has_multiselect = 1 unless has_multiselect
					matches.push submatches
			else
				_find_subquery q, matches

	return { query, matches, has_multiselect }



_find_subquery = (query,matches) ->
	subquery_matches = []
	## simple match, subject verb
	if -1 isnt query.search qr_subj_verb
		subquery_matches = query.match qr_subj_verb
		matches.push(subquery_matches.slice(1))
		#console.log "\t\tsubj verb match: #{subquery_matches} == subquery_matches.length = #{subquery_matches.length}"
		return 1
	## simple match, subject verb object
	else if (-1 is query.search qr_or_delimiter) and (subquery_matches = query.match qr_subj_verb_obj)
		matches.push subquery_matches.slice(1)
		#console.log "\t\tsubj verb obj match: #{subquery_matches.slice(1)}"
		return 1
	return 0

 
addResult = (data)->
	return unless data
	query = data.query
	matches = data.matches
	#console.log "addResults #{query}"
	_increment(finial,'has_multiselect') if data.has_multiselect? > 0
	#console.log "has multiselect? ", (exists data->{has_multiselect} and data->{has_multiselect} ? 'y' : 'n') ,"\n";
	for match in matches
		#console.log "match #{match}"
		if typeof match is 'string'
			continue
		if Object::toString.call(match[0]) isnt '[object Array]'
			_count_query match
			continue
		subj_seen = {}
		verb_seen = {}
		obj_seen = {}
		_count_query submatch,subj_seen,verb_seen,obj_seen for submatch in match
	return


_increment = (data,k) ->
	if k not of data
		data[k] = 1
	else
		data[k]++
	return

_count_query = (q,subj_seen,verb_seen,obj_seen) ->
	return unless q
	[subj,verb,obj] = q if q
	return unless subj and verb
	#console.log "subj #{subj} verb #{verb} obj #{obj ? 'undef'}"
	if subj_seen and verb_seen and obj_seen
		unless subj of subj_seen
			subj_seen[subj] = 1
			_increment finial,"subject\t#{subj}"
			_increment finial,"multiselect_subject\t#{subj}"

		unless verb of verb_seen
			verb_seen[verb] = 1
			_increment finial,"verb\t#{verb}"
			_increment finial,"multiselect_verb\t#{verb}"

		if obj and obj not of obj_seen
			obj_seen[obj] = 1
			_increment finial,"object\t#{obj}"
			_increment finial,"multiselect_object\t#{obj}"
	else
		_increment finial,"subject\t#{subj}"
		_increment finial,"verb\t#{verb}"
		_increment(finial,"object\t#{obj}") if obj



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


##open my queries_fh, ">queries_file.queries" or die "Can't create queries_file.queries, !\n"

#
# Shove all filenames to be parsed into an Object
# Will delete each filename from Object and when Object is empty
# will run a report function that outputs the parse results
#
file = process.argv[2]
queries_fh = bwriter.open (file + '.queries')
queries_fh.on 'error', (error) -> console.log "queries error: #{error}"
results_fh = bwriter.open (file + '.results')
results_fh.on 'error', (error) -> console.log "results error: #{error}"
new DataReader(file, encoding: 'utf8')
	.on('error', (error) -> console.log error)
	.on('line', (line, nextByteOffset) ->
		q = getQueryField line
		return unless q
		logQuery queries_fh,q
		addResult parseQuery q
	)
	.on('end', () ->
		#
		# at the end of each parsed file, remove that filename from the files Object
		# so that when Object has no keys, run the function, report, that writes out
		# the combined results to a file called 'results'
		#
		#delete files[file]
		#if (key for key, value of files).length is 0
			#queries_fh.close()
		report finial,results_fh
		return unless offset
		new BinaryReader(file).seek offset,(error) ->
			return close(@, error) if error)
	.read()
