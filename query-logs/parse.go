

package main

import (
	"bufio"
	"fmt"
	"os"
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

func debug_record( line string ) {
	fmt.Printf("%s\n",line )
}

