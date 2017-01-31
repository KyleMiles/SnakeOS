[BITS 16]
[ORG 0x7C00]

;This file is a bootloader that contains:
; 1: Printing a Character
; 2: Printing a string
; 3: Reseting drive we are reading
; 4: Reading the second stage bootloader

_start:
 JMP LOAD16

							;PARAMETERS FOR FILE SYSTEM

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
bsDriveNumber: 	        DB 0
bsUnused: 	            DB 0
bsExtBootSignature: 	DB 0x29
bsSerialNumber:	        DD 0xa0a1a2a3
bsVolumeLabel: 	        DB "SSSSSnakeOS"
bsFileSystem: 	        DB "FAT12   "

PRINTCHAR16:				;PRINT A CHARACTER
 MOV AH,0x0E
 MOV BH,0x00
 MOV BL,0x07
 
 INT 0x10
 RET
 
PRINTSTR16:					;PRINT A STRING
 NEXT:
 MOV AL,[SI]				;MOVE CHARACTER INTO AL
 INC SI						;INCREMENT MEMORY LOCATION
 OR AL,AL					;CHECK FOR ZERO-TERMINATED STRING
 JZ EXIT
 CALL PRINTCHAR16			;PRINT THE CURRENT CHAR
 JMP NEXT					;LOOP BACK B/C IT HAS NOT REACHED ZERO
 EXIT:
 RET
 
ResetDrive16:
 MOV AH,0					;RESET DRIVE
 MOV DL,0					;DRIVE NUMBER          LOOK INTO THIS!!
 INT 0x13
 JC  ResetDrive16
 
 MOV AX,0x1000				;READ SECTOR INTO ADDRESS 0x1000:0
 MOV ES,AX
 XOR BX,BX
 
 RET
 
Read16:						;READ MEMORY
 MOV AH,0x02				;READ SECTORS
 MOV AL,1					;SECTORS TP READ 1
 MOV CH,1					;CYLINDER 1
 MOV CL,2					;SECTORS TO READ
 MOV DH,0					;HEAD TO READ WITH
 MOV DL,0					;DRIVE TO READ FROM
 INT 0x13
 JC  Read16
 
;==================WHERE SHIT GOES DOWN!==================;
LOAD16:
 XOR AX,AX					;MAKE SURE WE ARE READING FROM MEMORY LOCATION ZERO
 MOV DS,AX
 MOV ES,AX
 
 MOV SI,ResetingDrive		;ALERT USER THAT THE DRIVE IS BEING RESET
 CALL PRINTSTR16
 
 CALL ResetDrive16			;RESET THE DRIVE
 
 MOV SI,DriveReset			;WELL, IT DIDN'T CHRASH...  MIGHT AS WELL ASSUME IT WORKED
 CALL PRINTSTR16
 
 MOV SI,ReadingSecondStage	;READ THE SECOND STAGE ALERT
 CALL PRINTSTR16
 
 CALL Read16
 
 MOV SI,FirstStagePassing	;PASS OFF TO SECOND STAGE
 CALL PRINTSTR16
 
 JMP 0x1000:0x0				;JUMP TO OUR NOW LOADED CODE
 
 
 ;==================VARIABLES==================;
 
 ResetingDrive		DB 'Drive is about to be reset... ',0
 DriveReset			DB 'Making the assumption that it worked because, well, you ARE reading this... ',0
 ReadingSecondStage DB 'Okay, NOW we pray...  Reading the second stage. ',0
 FirstStagePassing 	DB 'First Stage Handing Off... ',0
 SecondStageGrab	DB 'Second Stage Grabbed!',0
 
 times 510-($-$$) DB 0
 DW 0xAA55
 
 
;SECOND STAGE BOOT LOADER
 
ORG 0x1000

 MOV SI,SecondStageGrab
 CALL PRINTSTR16
 
 CLI						;CLEAR INTERUPTS
 HLT						;HALT SYSTEM
