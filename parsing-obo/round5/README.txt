
$ cd oboformat-read-only/bin/

## Edit obolib-basic,

from  

CMD="$JAVAPATH -d64 -Xmx2048M -Xms2048M -DentityExpansionLimit=512000 -DlauncherDir=$PATH_TO_ME -jar $PATH_TO_ME/oboformat-all.jar  $JAVAARGS $CMDARGS"

to 

CMD="$JAVAPATH -DentityExpansionLimit=512000 -DlauncherDir=$PATH_TO_ME -jar $PATH_TO_ME/oboformat-all.jar  $JAVAARGS $CMDARGS"


$ ./obolib-obo2owl -o file://`pwd`/gazetteer.round5.owl gazetteer.round5.obo 

