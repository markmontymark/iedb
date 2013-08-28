

package main

import (
	"bufio"
	//"encoding/csv" 
	"fmt"
	//"io"
	"os"
	"strings"
	"./querylogs"
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

func parse (filename string) {
    f, err := os.Open(filename)
    if err != nil {
        fmt.Println(err)
        return
    }
    defer f.Close()
    r := bufio.NewReaderSize(f, 1024*1024)
    line, isPrefix, err := r.ReadLine()
    for err == nil && !isPrefix {
        s := string(line)
	//fmt.Println(s)
			querylogs.Parserecord( s )
        line, isPrefix, err = r.ReadLine()
    }
    if isPrefix {
        fmt.Println("buffer size to small")
        return
    }
}

func prevarse( filename string ) {
	file, err := os.Open( filename )
	if err != nil {
		fmt.Printf("error opening file: %v\n",err)
		os.Exit(1)
	}

	fmt.Printf("processing file %s\n",filename)
	scanner := bufio.NewScanner( file )
	for scanner.Scan() {
		querylogs.Parserecord( scanner.Text() )
		//fmt.Println(scanner.Text()) // Println will add back the final '\n'
	}
	if err := scanner.Err(); err != nil {
		fmt.Fprintln(os.Stderr, "reading standard input:", err)
	}
/*
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
		querylogs.Parserecord( record )
	}
	tests.Test_count_per_record_results()
*/
}

func debug_record( record []string ) {
	fmt.Printf("%d records in%s\n", len(record), strings.Join(record,","))
}

