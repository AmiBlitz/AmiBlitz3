/*ADDRESS REXX*/
ADDRESS REXX
SAY "AGcheck..."
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

basedir = "Development:AmiBlitz3/Docs"
/*filename = "graphics/coerce.ab3"*/

SAY "listing directory of " || basedir
dirlist = SHOWDIR(basedir)
DO forever
    PARSE VAR dirlist dirname dirlist
    IF dirname = "" THEN LEAVE

    currentdir = basedir || "/" || dirname
    filelist = SHOWDIR(currentdir,"f")
    IF LENGTH(filelist)>0 THEN DO
        /* scanning the current directory */
        SAY "***** scanning " || dirname
        DO forever
            PARSE VAR filelist filename filelist
            IF filename = "" THEN LEAVE
            If RIGHT(filename,5) = "guide" THEN
                call processfile(currentdir, filename)
        END
    END
    ELSE 
        call processfile(basedir, dirname)
END

SAY "Finished"
EXIT


replace: procedure
    parse arg text,srch, repl
    slen = length(srch)
    tlen = length(text)
    SAY "replacing" srch "with" repl
    do until tlen = 0
        tlen = lastpos(srch, text, tlen)
        if tlen ~= 0 then DO
            text = insert(repl, delstr(text,tlen,slen), tlen-1)
            tlen = tlen - 1
        END
    END
    return text

addlines: procedure
    parse arg first, second
    SAY "beginning of code found, adding compiler directive."
    writeln('out',"CNIF @#"first"_"second"_H=0")
    writeln('out',"#"first"_"second"_H = 1")
    return 1

getArea: procedure
    parse arg if
    text = REVERSE(UPPER(if))
    text = SUBSTR(text,INDEX(text,"/")+1)
    text = REVERSE(text)
    text = SUBSTR(text,lastpos("/",text)+1)
    return text

getHeader: procedure
    parse arg if
    text = UPPER(if)
    text = LEFT(text,lastpos(".",text)-1)
    text = SUBSTR(text,lastpos("/",text)+1)
    return text

processfile: procedure
    parse arg basedir, filename

    incfile = basedir || "/" || filename

    IF open('inc', incfile, "r") THEN DO
        /*SAY "processing file" incfile*/
        DO UNTIL EOF('inc')
            currline = readln('inc')
        END
        IF Length(currline) > 0 THEN DO
            SAY "No LF at end of File " incfile
            /*SAY ">>" currline*/
        END
        CALL close('inc')
    END
    ELSE
        say "ERROR: could not open " incfile