[BITS 16]
[ORG 0x7C00]

MOV SI,HelloString
CALL PRINTSTR
JMP $

PRINTCHAR:
 MOV AH,0x0E
 MOV BH,0x00
 MOV BL,0x07
 
 INT 0x10
 RET
 
PRINTSTR:
 NEXT:
 MOV AL,[SI]
 INC SI
 
 OR AL,AL
 JZ EXIT
 
 CALL PRINTHCAR
 JMP NEXT
 
 EXIT:
 RET
 
 HelloString DB 'Operating System Loaded.'
 
 times 510-($-$$) DB 0
 DW 0xAA55
