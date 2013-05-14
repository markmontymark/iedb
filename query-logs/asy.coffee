Q = require 'q'
async = require 'asyncjs'
bwriter = require 'buffered-writer'
breader = require 'buffered-reader'
DataReader = breader.DataReader

filenamesjoined = 'asy'
queries_file = filenamesjoined + '.queries'
results_file = filenamesjoined + '.results'
queries_fh = bwriter.open queries_file
queries_fh.on 'error', (error) -> console.log "queries error: #{error}"
results_fh = bwriter.open results_file
results_fh.on 'error', (error) -> console.log "results error: #{error}"

qr_subj_verb = /^\s*([^,]+)\s+(is\s+excluded)\s*$/
qr_subj_verb_obj = /^\s*([^,]+)\s+(equals|contains|is|blast)\s+([^,]+)\s*$/
qr_or_delimiter = /\s+or\s+/

finial = {}

getQueryField = (data) ->
	return unless data
	return if data.indexOf('#') is 0
	[f0,f1,f2,f3,f4,f5,f6...] = data.split /[|]/
	query = f6.join ''

	# Deal with query having | char in it, ie entire field isn't quoted if it contains the delimiter character
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
	has_multiselect = false
	unless _find_subquery query,matches
		for q in query.split(/,/)
			if -1 isnt q.search( qr_or_delimiter)
				submatches = []
				for submatch in q.split(qr_or_delimiter)
					_find_subquery submatch, submatches
				if submatches.length > 0
					has_multiselect = true unless has_multiselect
					matches.push submatches
			else
				_find_subquery q, matches

	return { query, matches, has_multiselect }



_find_subquery = (query,matches) ->
	subquery_matches = null
	###### It's a subject verb match
	if -1 isnt query.search qr_subj_verb
		subquery_matches = query.match qr_subj_verb
		subquery_matches = (m.replace(/^\s+/,'').replace(/\s+$/,'') for m,i in subquery_matches.slice(1))
		matches.push(subquery_matches)
		return true
	###### It's a subject verb object match
	else if ( 
		(-1 is query.search qr_or_delimiter ) and 
		(subquery_matches = query.match qr_subj_verb_obj)
	)
		subquery_matches = (m.replace(/^\s+/,'').replace(/\s+$/,'') for m in subquery_matches.slice(1))
		matches.push(subquery_matches)
		return true
	return false

 
addResult = (data) ->
	return unless data
	query = data.query
	matches = data.matches
	_increment(finial,'has_multiselect') if data.has_multiselect?
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
	console.error "calling report"
	rdefer = Q.defer()
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
	rdefer.promise


processFile = (file) ->
	mdef  = Q.defer()
	dr = new DataReader(file.path, encoding: 'utf8')
		.on('error', (error) ->
			console.log error
			return mdef.reject(error)
		)
		.on('line', (line, nextByteOffset) ->
			q = getQueryField line
			return unless q
			logQuery queries_fh,q
			addResult parseQuery q
		)
		.on('end', (file) ->
			console.error("end on file ",file)
			mdef.resolve()
		)
		.read()
	mdef.promise

promises_array = []
asy = (path, callback) ->
	async.walkfiles(path, null, async.POSTORDER)
	.stat()
	.filter( (file) -> return file.stat.isFile() )
	.each( (file) -> promises_array.push( processFile(file) ))
	.end( -> return promises_array )

pa = Q.fcall( -> asy process.argv[2]).then( -> report finial,results_fh)
#queries_fh.close()
#report finial,results_fh)
