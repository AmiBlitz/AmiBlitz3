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

basedir = "Development:AmiBlitz3/Sourcecodes/includes/os"
/*filename = "graphics/coerce.ab3"*/

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
        If RIGHT(filename,3) = "ab3" THEN
            call processfile(currentdir, filename)
        ELSE
            say "skipping " || filename
    END
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
    outfile = incfile".new"
    area = getArea(incfile)
    headername = getHeader(incfile)

    SAY "processing file" incfile ", group " area ", " headername "..."

    IF open('inc', incfile, "r") THEN DO
        IF open('out',outfile,"w") THEN DO
            DO UNTIL EOF('inc')
                currline = readln('inc')
                /*IF length(currline) > 0 THEN writeln('out', currline)*/

                IF lastpos("/XTRA",currline) > 0 THEN DO
                    writeln('out', currline)

                    currline = readln('inc')
                    IF index(currline,"CNIF") = 0 THEN
                        finishhim = addlines(area,headername)
                    ELSE DO
                        SAY "file already updated."
                        EXIT
                    END
                END

                /* improve LSL - Code */
                IF LASTPOS("LSL", currline) > 0 THEN
                    IF SUBSTR(currline,LASTPOS("LSL",currline)-1,1) = "1" THEN
                        currline = replace(currline,"LSL"," LSL ")

                /* improve xincludes */
                IF LASTPOS("XINCLUDE", currline) > 0 THEN
                    DO
                        say currline
                        temp = SUBSTR(currline,INDEX(currline,'"')+1)
                        a = getArea(temp)
                        b = getHeader(temp)
                        wrt = compress(a "_" b "_H=0")
                        wrt2= compress(a "_" b "_H")
                        writeln('out', "CNIF @#"wrt)
                        writeln('out', currline)
                        writeln('out', "CEND ;"wrt2)
                    END
                ELSE
                    writeln('out', currline)

            END
            IF finishhim=1 THEN writeln('out',"CEND")

            CALL close('inc')
            CALL close('out')
            delete(incfile)
            rename(outfile, incfile)
        END
    END
    ELSE
        say "ERROR: could not open " incfile