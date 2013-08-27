package mab

import (
	"fmt"
	"io"
	"os"
	"sort"
)


var (
	col_ab_name_to_find string = "ab_name"
	col_reference_id_to_find string = "reference_id"
	dupe_abname_idx int = -1
	dupe_refid_idx int = -1
	dupe_line_count int = 0
	dupe_out
	dupe_once
	dupe_many
	dupe_oneref
	dupe_abname_count = {}
	dupe_many_abname = {}
	test boolean = false
)

type callback func( csv *io.Writer, row []string, field string)

func dupe_multivalue (file string) {
	outfile := strings.Replace(file,"before","after",-1)
	dupe_out, err := os.Open(outfile)
	if err != nil {
		fmt.Printf("couldn't create file %s: %s\n", outfile, err)
		os.Exit(1)
	}
	inputfile := os.Open(file)
	if err != nil {
		fmt.Printf("couldn't open file %s: %s\n", inputtfile, err)
		os.Exit(1)
	}
	process_file(inputfile, dupe_header_cb, dupe_line_cb, dupe_field_cb)

	fmt.Printf("number of rows: dupe_line_count\n")
	fmt.Printf("number of ab_names: %d\n", len(dupe_abname_count) )
	sorted_keys := make([]string,0)
	for k := range dupe_abname_count {
		sorted_keys = append(sorted_keys,k)
	}
	sort.Strings(sorted_keys)
	
	only1 := 0
	for k := range sorted_keys {
		if dupe_abname_count[k]["count"] == 1 {
			only1 ++ 
		}
	}
	fmt.Printf("number of ab_names seen only once: only1\n")
	fmt.Printf("duplicated abnames:\n")
	for k := range sorted_keys {
		if dupe_abname_count[k]["count"] > 1 {
			fmt.Printf("_ seen dupe_abname_count->{_}->{count} times\n" )
		}
	}
}

func dupe_ab_name_once (file string) {
	oncefile := strings.Replace(file, "before","once",-1)
	manyfile := strings.Replace(file, "before","many",-1)
	oneref   := strings.Replace(file, "before","oneref",-1)
	open dupe_once, ">", oncefile or die "oncefile: !"
	open dupe_many, ">", manyfile or die "manyfile: !"
	open dupe_oneref, ">", onereffile or die "onereffile: !"
	open my io, "<", file or die "file: !"
	process_file(io,dupe_header_cb,dupe_line_cb,dupe_once_field_cb)
}

func dupe_verify_once_and_oneref_not_in_many(file string) {
	oncefile := strings.Replace(file, "before","once",-1)
	manyfile := strings.Replace(file, "before","many",-1)
	oneref   := strings.Replace(file, "before","oneref",-1)
	open dupe_once, "<", oncefile or die "oncefile: !"
	open dupe_oneref, "<", onereffile or die "onereffile: !"
	open dupe_many, "<", manyfile or die "manyfile: !"

	//# undef here is for the header_cb, it's not needed because prior top-level loop dupe_* subs have parsed the header line for column indexes already
	process_file(dupe_many,undef,dupe_line_cb,dupe_read_in_field_cb)
	fmt.Printf("The leftovers file has %d abnames\n", len(dupe_many_abname) )
	process_file(dupe_once,undef, dupe_line_cb,  dupe_verify_field_cb)
	process_file(dupe_oneref,undef,dupe_line_cb,  dupe_verify_field_cb)
}

func dupe_header_cb (csv *io.Writer, row []string) {
	csv.print(dupe_out,row)
	idx := -1
	for _,field := range row {
		idx++
		if /^\s*col_ab_name_to_find\s*/i {
			dupe_abname_idx = idx
		}
		elsif(/^\s*col_reference_id_to_find\s*/i)
		{
			dupe_refid_idx = idx
		}
		last if dupe_abname_idx != -1 and dupe_refid_idx != -1
	if dupe_abname_idx == -1 {
		fmt.Printf("Didn't find col_ab_name_to_find column\n")
		os.Exit(1)
	}
	if dupe_refid_idx == -1 {
		fmt.Printf( "Didn't find col_reference_id_to_find column\n" )
		os.Exit(1)
	}
}

func dupe_line_cb (csv *io.Writer, row []string) {
	my(csv,row,field_cb) = @_
	dupe_line_count ++ 
	my field = row->[dupe_abname_idx]
	//# some fields have multiple values delimited by commas
	if(index(field,',') > -1)
	{
		for f := range strings.Split(field,",") {
			//# some fields have multiple values delimited by commas and the word 'and'
			if regexp.MatchString("and",f) {
				for ands := strings.Split("and",f) {
					field_cb(csv,row,ands) 
				}
			} else {
				field_cb(csv,row,f)
			}
		}
	}
	//# some fields have multiple values delimited only the word 'and'
	elsif(field =~ /\sand\s/)
	{
		field_cb->(csv,row,_) for split /\sand\s/,field
	}
	//# some fields have only one value (or at least no commas or 'and' words)
	else
	{
		if(field =~ /^\s*/) {

			fmt.Printf("empty ab_name in row: dupe_line_count\n"

		} else {

			field_cb(csv,row,field)

		}
	}
}

func dupe_field_cb (csv *io.Writer, row []string, field string {
	field = strings.Trim(field)
	
	if matched := regexp.MatchString( "^\s*$"); matched != nil {
		fmt.Printf("empty ab_name in row: dupe_line_count\n")
	}
	row[dupe_abname_idx] = field
	dupe_abname_count[field]["count"]++ 
	csv.print(dupe_out,row)

	ref_field = row[dupe_refid_idx]
	ref_field = strings.Trim(ref_field)
	if ref_field != nil && ref_field != "" {
		dupe_abname_count[field]["refs"][ref_field]++ 

	} else {

		fmt.Printf("ref field empty in row: dupe_line_count\n")
	}
}

func dupe_once_field_cb (csv *io.Writer, row []string, field string) {
	field = strings.Trim( field )
	if matched,_ := regexp.MatchString("^\s*$",field); matched != nil {
		return
	}
	
	if val,exists := dupe_abname_count[field]; exists {
		row[dupe_abname_idx] = field
		maybe_do_many := 0
		if dupe_abname_count[field]["count"] == 1 {
			csv.print(dupe_once,row)
			if scalar(keys %{dupe_abname_count->{field}->{refs}}) != 1 {
				fmt.Printf("does this ever happen? field\n"
			}

		} else {
			maybe_do_many = 1
		}

		if( scalar(keys %{dupe_abname_count->{field}->{refs}}) == 1) {
			maybe_do_many = 0
			csv.print(dupe_oneref,row)
		}
		if maybe_do_many > 0 {
			csv.print(dupe_many,row)
		}
	}
	else
	{
		fmt.Printf("Field field, not found in dupe_abname_count!!\n"
	}
}

func dupe_read_in_field_cb (csv *io.Writer, row []string, field string) {
	field = strings.Trim(field)
	if field == "" {
		return
	}
	dupe_many_abname[field]++
}

func dupe_verify_field_cb  (csv *io.Writer, row []string, field string) {
{
	field = strings.Trim(field)
	if field == "" {
		return
	}
	if v,exists := dupe_many_abname[field] ; exists {
		fmt.Printf("this shouldn't happen, field field is in many file and this file\n"
	}
}

func process_file (filename string , header_cb callback,line_cb callback ,field_cb callback) {
   file, err := os.Open( filename )
   if err != nil {
      fmt.Printf("error opening file: %v\n",err)
      os.Exit(1)
   }

   fmt.Printf("processing file %s\n",filename)
   data := csv.NewReader( file )
   for {
      row, rerr := data.Read()
      if rerr != nil {
         if rerr != io.EOF {
            fmt.Printf("error reading file: %v\n",rerr)
            os.Exit(1)
         }
         break
      }

      //debug_record( record )
		line_cb(csv,row,field_cb)
   }
}

