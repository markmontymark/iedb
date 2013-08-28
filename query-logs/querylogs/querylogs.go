package querylogs


import (
	"fmt"
	"regexp"
	"strings"
)

var (
	qr_subj_verb *regexp.Regexp = regexp.MustCompile("^\\s*([^,]+)\\s+(is\\s+excluded)\\s*$")
	qr_subj_verb_obj *regexp.Regexp = regexp.MustCompile("^\\s*([^,]+)\\s+(equals|contains|is|blast)\\s+([^,]+)\\s*$")
	qr_or_delimiter *regexp.Regexp = regexp.MustCompile("\\s+or\\s+")
)


func Parserecord( record string ) {
	parseQuery(getQueryField( record) )
}

func getQueryField ( record string) string {
	if record == "" {
		return ""
	}

	fields := strings.Split( record, "|" )
	if len(fields) < 7 {
		return ""
	}
	query  := strings.Join( fields[6:], "")
	
	yes_no_idx := 0
	for _,v := range fields[6:] {
		if matched, _ := regexp.MatchString("(yes|no)", v ) ; matched {
			break
		}
		yes_no_idx++
	}
	
	if yes_no_idx > 0 {
		q := make([]string,0)
		for i := 0; i <= (yes_no_idx - 2) ; i++ {
			q = append(q, fields[6 + i])
		}
		query = strings.Join( q, "|" )
	}
	//fmt.Printf("%s yes_no_idx %d\n",query,yes_no_idx)
	return strings.TrimSpace( query )
}


type parseQueryRetval struct {
	Query string
	Matches []string 
	HasMultiSelect bool
}
	
func findSubQuery( query string, matches *[]string ) bool {

	if matched := qr_subj_verb.MatchString(query ) ; matched {

		subquery_matches := qr_subj_verb.FindAllString( query, -1 )
		for _,v := range subquery_matches {
			*matches = append( *matches, strings.TrimSpace( v ) )
		} 
		return true

	} else if (!qr_or_delimiter.MatchString(query)) && qr_subj_verb_obj.MatchString( query ) {
		subquery_matches := qr_subj_verb_obj.FindAllString( query, -1 )
		for _,v := range subquery_matches {
			*matches = append( *matches, strings.TrimSpace( v ) )
		}
		return true

	}

	return false

}

func parseQuery (query string)  parseQueryRetval {
	pqr := parseQueryRetval{query,make([]string,0), false}

	if query == "" {
		return pqr
	}

	if hasSubQueries := findSubQuery( query, &pqr.Matches );  ! hasSubQueries {
		for _,q := range strings.Split(query,",") {
			if qr_or_delimiter.MatchString( q ) {
				submatches := make([]string,0)

				for _, submatch := range strings.Split( q, " or ") {
					submatch = strings.TrimSpace(submatch)
					findSubQuery( submatch, &submatches )
				}

				if len(submatches) > 0 {
					pqr.HasMultiSelect = true
					pqr.Matches = append(pqr.Matches, "startsubmatch")
					for _, v := range submatches {
						pqr.Matches = append(pqr.Matches, v)
					}
					pqr.Matches = append(pqr.Matches, "endsubmatch")
				}

			} else {
				findSubQuery( q, &pqr.Matches )
			}
		}
	}

	return pqr	
}


func addResult (pqr parseQueryRetval ) {

	for _,v := range pqr.Matches {
		fmt.Printf("match is %s\n", v )
	}	
	
}








