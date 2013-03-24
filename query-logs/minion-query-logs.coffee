#!/usr/bin/env coffee

# Prereqs for `npm install`
# --------------
fs = require 'fs'
bwriter = require 'buffered-writer'
breader = require 'buffered-reader'
DataReader = breader.DataReader

# Regexes
# -------
# Match a query's subject, verb, and optional object words
# Queries can be one of 
#
# - Subject Verb
# - Subject Verb Object
#
# Queries can be separated by either a comma (which means mulitple queries) or the word, 'or' (which means a 'multi-select' query).
# There can also be multiple multiselect queries.
#
# Query formats:
#
# - Q = at least one of ( S,V ) or ( S,V,O )
# - MQ = Q1 or Q2
# - Q , Q
# - Q or Q
# - MQ , Q
# - Q or MQ
qr_subj_verb = /^\s*([^,]+)\s+(is\s+excluded)\s*$/
qr_subj_verb_obj = /^\s*([^,]+)\s+(equals|contains|is|blast)\s+([^,]+)\s*$/
qr_or_delimiter = /\s+or\s+/


# finial
# ------
#
# holds the parsing results. keys of finial are in the format:
#
#  - subject \t count
#  - verb \t count
#  - object \t count
#  - has_multiselect \t count
#  - multiselect_subject \t count
#  - multiselect_verb \t count
#  - multiselect_object \t count
finial = {}

# getQueryField(data)
# -------------------
# Argument `data` is assumed to be a line of text of '|' separated values (or columns)
# What we want is the 7th column, but values of the columns can contain the | char.
# By using a later column that's guaranteed to have a 'yes' or 'no' value, we can mostly
# work around the problem of `split/[|]/` splitting text into too many columns

# input
#
#  - data = unparsed line from file
#
# output
#
# returns String of query column
#

getQueryField = (data) ->
	return unless data
	return if data.indexOf('#') is 0
	[f0,f1,f2,f3,f4,f5,f6...] = data.split /[|]/
	query = f6.join ''

	# Deal with query having | chars in it, ie entire field isn't quoted if it contains the delimiter character
	yes_no_idx = 0
	for f in f6
		break if /^\s*(?:yes|no)\s*$/.test f
		yes_no_idx++

	query = (f6[i] for i in [0..(yes_no_idx-2)]).join '|' unless yes_no_idx is 0
	return if /^\s*$/.test query
	query.replace(/^\s+/,'').replace(/\s+$/,'').replace(/\t/,'')

# logQuery(fh,data)
# -----------------
# input
#
#  - fh = open file handle to log file
#  - data = text to log
#
# output
#
#  returns undefined
#

logQuery = (fh,data) ->
	return unless data
	fh.write data
	fh.write "\n" unless /\n$/.test data


# parseQuery(data)
# ---------------------
# - query = Original query text, unparsed
# - matches = Array of N many queries where a query can be:
#  - [Subject,Verb] 
#  - [Subject,Verb,Object] 
#  - [ [Subject,Verb], [Subject,Verb,Object], ... ] (this is a multiselect query)
# - has_multiselect = Boolean, true if query had at least one multiselect query (queries separated by 'or' keyword)
#
# input
#
#  - data = query column from line of data
#
# output
#
#  returns object with keys:
#
parseQuery = (query) ->
	return unless query

	matches = []
	has_multiselect = 0
	unless _find_subquery query,matches
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


# _find_subquery(query,matches)
# -----------------------------
# Uses `qr_subj_verb` and `qr_subj_verb_obj` regexes defined at top and tries to 
# match whole text, `query`, with the regexes.  
#
# input
#
# - data = query column from line of data
# - matches = Array to store matches found 
#
# output
#
#  returns Boolean, whether or not a match was found

_find_subquery = (query,matches) ->
	subquery_matches = []
	###### simple match, subject verb
	if -1 isnt query.search qr_subj_verb
		subquery_matches = query.match qr_subj_verb
		subquery_matches = (m.replace(/^\s+/,'').replace(/\s+$/,'') for m in subquery_matches.slice(1))
		matches.push subquery_matches
		return 1
	###### simple match, subject verb object
	else if (-1 is query.search qr_or_delimiter) and (subquery_matches = query.match qr_subj_verb_obj)
		subquery_matches = (m.replace(/^\s+/,'').replace(/\s+$/,'') for m in subquery_matches.slice(1))
		matches.push subquery_matches
		return 1
	return 0


# addResult(data)
# -----------------------------
# Iterate over parseQuery `matches` to aggregate results, adding and incrementing 
# data in `finial` object
#
# input
#
#  - object = return value from `parseQuery`
#
# output
# return undefined
addResult = (data)->
	return unless data
	query = data.query
	matches = data.matches
	_increment(finial,'has_multiselect') if data.has_multiselect? > 0
	for match in matches
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

# _increment(data,k)
# -----------------------------
# Increment the value at `data[k]` if k exists, else, adding k to data with initial value of 1
#
# input
#
# - data = object to test for existence of k
# - k = String
#
# output
# returns undefined
_increment = (data,k) ->
	if k not of data
		data[k] = 1
	else
		data[k]++
	return


# _count_query(q,subj_seen,verb_seen,obj_seen)
# --------------------------------------------
# Increment subjects, verbs, and objects found in a query.  
# Only increment a subject, verb or object once if in multiple times from a multiselect query
#
# input
#
# - q = Array of query words.  Can be:
#  - Subject, Verb
#  - Subject, Verb, Object
# - subj_seen Object
# - verb_seen Object
# - obj_seen Objects containing Subjects, Verbs, Objects seen so far when iterating a multiselect query
#
# output
# returns undefined 

_count_query = (q,subj_seen,verb_seen,obj_seen) ->
	return unless q
	[subj,verb,obj] = q if q
	return unless subj and verb
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


# _report(obj,opt_fh)
# --------------------------------------------
# Write a .results file with data from `obj` sorted descending by `obj` values
#
# input
#
# - obj = results object to iterate over
# - opt_fh = optional open file handle to write data, else write to stdout
#
# output
# returns undefined

report = (res,opt_fh) ->
	kys = (k for k of res)
	kys.sort((a,b) -> return res[b] - res[a] )
	if opt_fh
		for k in kys
			opt_fh.write "#{k}\t#{res[k]}\n"
	else
		for k in kys
			console.log "#{k}\t#{res[k]}\n"
	opt_fh.close() if opt_fh


# Start of Main
# =============
#
# Create a .queries log file 
#
# Create a .results log file
#
file = process.argv[2]
queries_fh = bwriter.open (file + '.queries')
queries_fh.on 'error', (error) -> console.log "queries error: #{error}"
results_fh = bwriter.open (file + '.results')
results_fh.on 'error', (error) -> console.log "results error: #{error}"

# Read, parse, write out queries and results file from file passed in
new DataReader(file, encoding: 'utf8')
	.on('error', (error) -> console.log error)
	.on('line', (line, nextByteOffset) ->
		q = getQueryField line
		return unless q
		logQuery queries_fh,q
		addResult parseQuery q
	)
	.on('end', () -> report finial,results_fh)
	.read()
