/* tool to convert all files in a given directory from old bb2 format ab3 */
SAY "HELLO"
SAY "checking rexxsupport.library..."
IF SHOW(L,"rexxsupport.library") = 1 THEN
    SAY "available"
ELSE
    IF ADDLIB("rexxsupport.library",0,-30,0) = 1 THEN
        SAY "opened"
    ELSE DO
        SAY "could not open library"
        EXIT
    END

/* ------------------------------------------------------------- */

basedir = "'" Blitz3:Sourcecodes/Examples/Classic examples/test "'"

ADDRESS TEST

LOAD basedir
SAY "Finished"
EXIT