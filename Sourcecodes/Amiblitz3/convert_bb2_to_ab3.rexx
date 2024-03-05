/*ADDRESS REXX*/
SAY "HELLO"
SAY "checking rexxsupport.library..."
IF SHOW(L,"rexxsupport.library") = 1 THEN
    SAY "available"
ELSE
    IF ADDLIB("rexxsupport.library") = 1 THEN
        SAY "opened"
    ELSE DO
        SAY "could not open library"
        EXIT
    END

basedir = "Blitz3:Sourcecodes/includes/os"
SAY "listing directory of " || basedir
dirlist = SHOWDIR(basedir)
DO forever
    PARSE VAR dirlist dirname dirlist
    IF dirname = "" THEN LEAVE

    /* scanning the current directory */
    SAY "***** scanning " || dirname
    currentdir = basedir || "/" || dirname
    filelist = SHOWDIR(currentdir,"f")
    DO forever
        PARSE VAR filelist filename filelist
        IF filename = "" THEN LEAVE
        If RIGHT(filename,3) = "bb2" THEN DO
            say "converting " || filename
            fn = currentdir || "/" || filename
            nfn = replace(fn, ".bb2", ".ab3")

            ADDRESS PED.1
            LOAD fn
            SAVEAS nfn

            END
        ELSE
            say "skipping " || filename
    END
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
