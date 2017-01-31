BITS 16						;16 bit real mode
ORG 0

;############################;
;                            ;
;   FirstStage.asm           ;
;    - My First Bootloader   ;
;                            ;
;	SnakeOS                  ;
;    - Kyle Martin           ;
;                            ;
;############################;

;This file is a bootloader that contains:
; 1: Printing a Character
; 2: Printing a string
; 3: Reading the second stage bootloader
; 4: Launching Second Stage

;Error codes are as follows:
; 0: Before any actual work...
; 1: CalcRoot16
; 2: ReadNextStage16
; 3: PassingStage16

start:
 JMP LOAD16
;Bios Parameter Block
bpbOEM					DB "SSnakeOS"
bpbBytesPerSector:  	DW 512
bpbSectorsPerCluster: 	DB 1
bpbReservedSectors: 	DW 1
bpbNumberOfFATs: 	    DB 2
bpbRootEntries: 	    DW 224
bpbTotalSectors: 	    DW 2880
bpbMedia: 	            DB 0xF0
bpbSectorsPerFAT: 	    DW 9
bpbSectorsPerTrack: 	DW 18
bpbHeadsPerCylinder: 	DW 2
bpbHiddenSectors: 	    DD 0
bpbTotalSectorsBig:     DD 0
bsDriveNumber: 	        DW 0
bsExtBootSignature: 	DB 0x29
bsSerialNumber:	        DD 0xa0a1a2a3
bsVolumeLabel: 	        DB "SnakeOS    "
bsFileSystem: 	        DB "FAT12   "

PRINTCHAR16:				;PRINT THE CHARACTER IN AL
 PUSHA
  MOV AH,0x0E
  XOR BX,BX
  INT 0x10
 POPA
RET
 
PRINTSTR16:					;PRINT A STRING
 PUSHA
  NEXT:
  LODSB						;MOVES CURRENT CHARACTER INTO AL AND INCREMENTS SI
  OR AL,AL					;CHECK FOR ZERO-TERMINATED STRING
  JZ EXIT					;EXIT
  CALL PRINTCHAR16			;PRINT THE CURRENT CHAR
  JMP NEXT					;LOOP BACK B/C IT HAS NOT REACHED ZERO
  EXIT:
 POPA
RET

CalcRoot16:
 XOR CX,CX					;ZERO REGISTERS
 XOR DX,DX					;...
 MOV AX,0x0020				;32 BYTE DIRECTORY ENTIRIES
 MUL WORD[bpbRootEntries]	;NUMBER OF ROOT ENTRIES
 DIV WORD[bpbBytesPerSector];SECTORS USED BY ROOT
 XCHG AX,CX					;SAVE THE SIZE OF ROOT INTO CX
 
 MOV AL,BYTE[bpbNumberOfFATs];NUMBER OF FATS
 MUL WORD[bpbSectorsPerFAT]	;SECTORS USED BY FATS
 ADD AX,WORD[bpbReservedSectors];ADJUST FOR BOOT SECTOR
 MOV WORD[DATASECTOR],AX	;BASE OF ROOT DIRECTORY
 ADD WORD[DATASECTOR],CX
 
 MOV BX,0x0200
 CALL Read16
RET

CHS2LBA:					;CONVERT CHS TO LBA
 SUB AX,0x0002
 XOR CX,CX
 MOV CL,BYTE[bpbSectorsPerCluster]
 MUL CX
 ADD AX,WORD[DATASECTOR]
RET

LBA2CHS:					;CONVERT LBA TO CHS
 XOR DX,DX
 DIV WORD[bpbSectorsPerTrack]
 INC DL
 MOV BYTE[absoluteSector],DL
 XOR DX,DX
 DIV WORD[bpbHeadsPerCylinder]
 MOV BYTE[absoluteHead],DL
 MOV BYTE[absoluteTrack],AL
RET

Read16:
 MOV DI,0x0005
 ReadLoop:
 PUSH AX
  PUSH BX
   PUSH CX
    CALL LBA2CHS
    MOV AH,0x02				;READ SECTORS
    MOV AL,0x01				;HOW MANY SECTORS TO READ
    MOV CH,BYTE[absoluteTrack];CYLINDER 0
    MOV CL,BYTE[absoluteSector];SECTORS TO READ
    MOV DH,BYTE[absoluteHead];HEAD TO READ WITH
    MOV DL,BYTE[bsDriveNumber];DRIVE TO READ FROM
    INT 0x13				;TRY TO READ
    JNC GoodRead
    XOR AX,AX
    INT 0x13				;TRY TO READ AGAIN
    DEC DI					;ONE LESS TRY - MAX FIVE
   POP CX
  POP BX
 POP AX
 JNZ ReadLoop				;TRY, TRY AGAIN
 CALL FAILURE				;FAIL

    GoodRead:
   POP CX
  POP BX
 POP AX
 ADD BX,WORD[bpbBytesPerSector]
 INC AX
 LOOP Read16
RET

ReadNextStage16:
 MOV CX,WORD[bpbRootEntries];NUMBER OF ENTRIES, IF IT GETS DOWN TO ZERO, WE SCANNED ALL THE FILES
 MOV DI,0x0200				;WHERE WE LOADED THE ROOT DIRECTORY
 INLOOP:
  PUSH CX
   MOV CX,0x000B			;11 CHARACTER LONG NAME
   MOV SI,ImageName			;COMPARE OUR FILE NAMES
   PUSH DI
    REP CMPSB				;TEST FOR MATCH
   POP DI
   JE LOAD_FAT				;THEY MATCH, LOAD FAT
  POP CX
  ADD DI,0x0020				;NOT A MATCH, SCAN THE NEXT ENTRY
  LOOP INLOOP
  JMP FAILURE				;FILE DOES NOT EXIST

LOAD_FAT:
 POP CX
 MOV DX,WORD[DI+0x001A]		;ENTRY + 26 (TO GET TO THE CLUSTER BlUSTER FLUSTER INFORMATION)
 MOV WORD[CLUSTER],DX		;FILE'S FIRST CLUSTER
 
 XOR AX,AX					;CLEAR OUT REGISTER
 MOV AL,BYTE[bpbNumberOfFATs];NUMBER OF FATS
 MUL WORD[bpbSectorsPerFAT]	;SECTORS USED BY FATS
 MOV CX,AX					;STORE IN CX
 
 MOV AX,WORD[bpbReservedSectors]
 
 MOV BX,0x0200
 CALL Read16
RET

PassingStage16:
 MOV AX,0x0050				;MOVE TO 0050:0000
 MOV ES,AX
 MOV BX,0x0000
 PUSH BX
 LOAD_IMAGE:
  MOV AX,WORD[CLUSTER]
 POP BX
 CALL CHS2LBA				;CONVERT CLUSTER TO LBA
 XOR CX,CX
 MOV CL,BYTE[bpbSectorsPerCluster];CLUSTERS TO READ
 CALL Read16
 PUSH BX
 
 MOV AX,WORD[CLUSTER]		;GET CURRENT CLUSTER
 MOV CX,AX					;COPY
 MOV DX,AX					;...
 SHR DX,0x0001				;DIVIDE BY TWO
 ADD CX,DX					;SUM FOR 3/2
 MOV BX,0x0200				;READ TWO BYTES FROM FAT
 ADD BX,CX					;LOCATION OF FAT IN MEMORY
 MOV DX,WORD[BX]
 TEST AX,0x0001
 JNZ ODDCLUSTER
 
 EVENCLUSTER:
  AND DX,0000111111111111b
  JMP DONE
  
 ODDCLUSTER:
 SHR DX,0x0004
 
 DONE:
  MOV WORD[CLUSTER],DX
  CMP DX,0x0FF0
  JB  LOAD_IMAGE
 
 DONELOADING:
 POP BX
RET

FAILURE:
 MOV SI,Failure0
 CALL PRINTSTR16
 MOV AH,0x00
 INT 0x16
 INT 0x19

;====================MAIN====================;  

LOAD16:
 CLI
 MOV AX,0x07C0				;MAKE SURE WE ARE READING FROM MEMORY LOCATION ZERO
 MOV DS,AX
 MOV ES,AX
 MOV FS,AX
 MOV GS,AX
 
 MOV AX,0x0000				;CREATE THE STACK
 MOV SS,AX
 MOV SP,0xFFFF
 STI
 
 ;##############
 ;MOV SI,Failure0
 ;CALL PRINTSTR16
 ;##############
 
 CALL CalcRoot16
 
 ;##############
 ;MOV SI,Failure1
 ;CALL PRINTSTR16
 ;##############
 
 CALL ReadNextStage16
 
 ;##############
 ;MOV SI,Failure2
 ;CALL PRINTSTR16
 ;##############
 
 CALL PassingStage16
 
 ;##############
 ;MOV SI,Failure3
 ;CALL PRINTSTR16
 ;##############
 
 PUSH WORD 0x0050
 PUSH WORD 0x0000
RETF
 

 ;==================VARIABLES==================;

 Failure0			DB 10,13,"Fatal Error.",13,10,"Error Code: 0",0
 Failure1			DB 8,"1",0
 Failure2			DB 8,"2",0
 Failure3			DB 8,"3",0
 ImageName			DB "SNAKEOS SYS"
 CLUSTER			DW 0x0000
 DATASECTOR			DW 0x0000
 absoluteSector 	DB 0x00
 absoluteHead   	DB 0x00
 absoluteTrack  	DB 0x00
 
 times 510-($-$$) DB 0
 DW 0xAA55
