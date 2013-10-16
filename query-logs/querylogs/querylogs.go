package querylogs


import (
	"fmt"
	"regexp"
	"strings"
)

type parseQueryRetval struct {
	Query string
	Matches []string 
	HasMultiSelect bool
}

type Query struct {
	has_multiselect bool
	subqueries []Query
}

type SubQuery struct {
	subject,verb,object string
}

type set map[interface{}]bool

var (
	qr_subj_verb *regexp.Regexp = regexp.MustCompile("^\\s*([^,]+)\\s+(is\\s+excluded)\\s*$")
	qr_subj_verb_obj *regexp.Regexp = regexp.MustCompile("^\\s*([^,]+)\\s+(equals|contains|is|blast)\\s+([^,]+)\\s*$")
	qr_or_delimiter *regexp.Regexp = regexp.MustCompile("\\s+or\\s+")
)


func Parserecord( record string ) {
	addResult( parseQuery(getQueryField( record) ))
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
	//fmt.Printf("query %s\n", query)
	return strings.TrimSpace( query )
}


	
func findSubQuery( query string, matches []string ) (bool,[]string) {

	sv_matches := qr_subj_verb.FindAllString( query, -1 )
	fmt.Printf("query %v\n",query)
	if sv_matches != nil && len(sv_matches) > 0 { //matched := qr_subj_verb.MatchString(query ) ; matched {
		fmt.Printf("sv matches %v\n",sv_matches)
		//fmt.Printf("findSubQuery, matched on %s, query: %s\n",qr_subj_verb,query);
		//subquery_matches := qr_subj_verb.FindAllString( query, -1 )
		for _,v := range sv_matches {
			fmt.Printf("\t2 findSubQuery, append match %s\n",strings.TrimSpace(v))
			matches = append( matches, strings.TrimSpace( v )  )
		} 
		return true,matches

	} else {
		or_matched  := qr_or_delimiter.MatchString(query)
		svo_matches := qr_subj_verb_obj.FindAllString( query, -1 )
		fmt.Printf("or matched %v\n",or_matched)
		fmt.Printf("svo matches %v\n",svo_matches)
		//if (!qr_or_delimiter.MatchString(query)) && qr_subj_verb_obj.MatchString( query ) {
		if (!or_matched) && svo_matches != nil && len(svo_matches) > 0  {
			//subquery_matches := qr_subj_verb_obj.FindAllString( query, -1 )
			for _,v := range svo_matches {
				fmt.Printf("\t1 findSubQuery, append match %s\n",strings.TrimSpace(v))
				matches = append( matches, strings.TrimSpace( v ) )
			}
		}
		return true,matches

	}

	return false,matches

}

func parseQuery (query string)  parseQueryRetval {
	pqr := parseQueryRetval{query,make([]string,0), false}

	if query == "" {
		return pqr
	}

	if hasSubQueries,matches := findSubQuery( query, make([]string,0) );  ! hasSubQueries {
		pqr.Matches = matches
		for _,q := range strings.Split(query,",") {
			if qr_or_delimiter.MatchString( q ) {
				for _, submatch := range strings.Split( q, " or ") {
					submatch = strings.TrimSpace(submatch)
					has_submatches,submatches := findSubQuery( submatch, make([]string,0))
					if has_submatches {
						pqr.HasMultiSelect = true
						pqr.Matches = append(pqr.Matches, "startsubmatch")
						for _, v := range submatches {
							pqr.Matches = append(pqr.Matches, v)
						}
						pqr.Matches = append(pqr.Matches, "endsubmatch")
					}
				}

			} else {
				hasSubQueries,matches := findSubQuery( q, make([]string,0))
				if hasSubQueries {
					for _,v := range matches {
						pqr.Matches = append( pqr.Matches, v )
					}
				}
			}
		}
	} else {
		for _,v := range matches {
			pqr.Matches = append( pqr.Matches, v )
		}
	}
	

	return pqr	
}


func addResult (pqr parseQueryRetval ) {
	fmt.Printf("has multiselect %s\n", pqr.HasMultiSelect)
	fmt.Printf("match is %s\n", strings.Join(pqr.Matches,"--") )
	var subj_seen ,verb_seen, obj_seen set
	for _,v := range pqr.Matches {
		if v == "startsubmatch" {
			subj_seen = make(set)
			verb_seen = make(set)
			obj_seen  = make(set)
			continue
		}
		if v == "endsubmatch" {
			continue
		}
		countQuery( v, subj_seen, verb_seen, obj_seen )
		fmt.Printf("match is %s\n", v )
	}	
	fmt.Printf("\n\n")
}

func countQuery(query string, s,v,o set) {
	
}
