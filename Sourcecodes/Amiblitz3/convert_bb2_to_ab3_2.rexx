/* tool to convert all files in a given directory from old bb2 format ab3 */

SAY "Sourcecode converter script started."
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

basedir = "Amiblitzbasicgamejam:hyperrunner/includes"

SAY "listing directory of " || basedir

entrylist = SHOWDIR(basedir)
DO forever
    PARSE VAR entrylist entry entrylist
    IF entry = "" THEN LEAVE

    If RIGHT(entry,3) = "bb2" | RIGHT(entry,3) = "ab2" THEN DO

            fn = "'" || basedir || "/" || entry || "'"
            nfn = replace(fn, ".bb2", ".ab3")
            nfn = replace(nfn, ".ab2", ".ab3")

            SAY "converting " || entry || " to " || nfn

            ADDRESS PED.1
            LOAD fn
            SAVEAS nfn
        END
    /* ELSE
        SAY "skipping " || entry*/
    
END

SAY "Finished"
EXIT


replace: procedure
    parse arg text, srch, repl
    slen = length(srch)
    tlen = length(text)
    do until tlen = 0
        tlen = lastpos(srch, text, tlen)
        if tlen ~= 0 then DO
            text = insert(repl, delstr(text,tlen,slen), tlen-1)
            tlen = tlen - 1
        END
    END
    return text
