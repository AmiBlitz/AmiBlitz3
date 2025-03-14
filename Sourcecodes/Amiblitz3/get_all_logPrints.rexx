/*ADDRESS REXX*/
SAY "HELLO"
SAY "checking rexxsupport.library..."
IF SHOW(L,"rexxsupport.library") = 1 THEN
    SAY "available"
ELSE
    IF ADDLIB("rexxsupport.library",0) = 1 THEN
        SAY "opened"
    ELSE DO
        SAY "could not open library"
        EXIT
    END
/*---------------------------------------------*/

filename = "PED/PED.ab3"

SAY "scanning for log_prints in " || filename
CALL processfile filename
SAY "Finished"
EXIT

processfile: procedure
    parse arg filename

    IF OPEN('inc', filename, "r") THEN DO
        IF OPEN('out',filename || ".log", "w") THEN DO
            DO UNTIL EOF('inc')
                currline = READLN('inc')
                IF INDEX(currline,"log_Print") > 0 THEN DO
                    SaY currline
                    writeln('out', currline)
                END
            END
            CALL CLOSE('inc')
            CALL CLOSE('out')
        END
        ELSE
            SAY "ERROR: could not open " || filename || ".log"
    END
    ELSE
        SAY "ERROR: could not open " filename    