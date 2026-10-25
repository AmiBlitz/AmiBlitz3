/* drive PED via ARexx: load each probe, build executable, collect errors */
OPTIONS RESULTS
ADDRESS 'PED.1'
'VERSION'
SAY 'version:' result
'ERRORREQ OFF'
SAY 'errorreq previous=' result
probes = 'ide_join ide_argjoin'
DO i = 1 TO WORDS(probes)
  p = WORD(probes, i)
  'LOAD SPEC:probes/ide/'p'.ab3'
  SAY p 'load rc=' rc
  'NUMLINES'
  SAY p 'numlines=' result
  'MAKEEXEC RAM:'p
  SAY p 'makeexec rc=' rc
  'LASTERROR'
  SAY p 'lasterror=' result
  IF EXISTS('RAM:'p) THEN ADDRESS COMMAND 'RAM:'p' >SPEC:results/'p'.out.txt'
END
SAY 'rexx done'
EXIT 0
