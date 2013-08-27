

package main

import (
	"encoding/csv" 
	"fmt"
	"io"
	"os"
	"strings"
	"./tests"
)

var (
	test_count_per_record_data = make(map[int]int)
)

func main() {
	for i,filename := range os.Args {
		if i == 0 {
			continue
		}
		parse( filename )
	}
}

func parse( filename string ) {
	file, err := os.Open( filename )
	if err != nil {
		fmt.Printf("error opening file: %v\n",err)
		os.Exit(1)
	}

	fmt.Printf("processing file %s\n",filename)
	data := csv.NewReader( file )
	for {
		record, rerr := data.Read()
		if rerr != nil {
			if rerr != io.EOF {
				fmt.Printf("error reading file: %v\n",rerr)
				os.Exit(1)
			}
			break
		}

		//debug_record( record )
		tests.Test_count_per_record( record )
	}
	tests.Test_count_per_record_results()
}

func debug_record( record []string ) {
	fmt.Printf("%d records in%s\n", len(record), strings.Join(record,","))
}

/*
func test_count_per_record( record []string ) {
	test_count_per_record_data[ len(record) ]++
	
}

func test_count_per_record_results() {
	fmt.Printf("test_count_per_record results\n")
	for k,v := range test_count_per_record_data {
		fmt.Printf("%d records in %d lines\n", k, v )
	}
}
*/
