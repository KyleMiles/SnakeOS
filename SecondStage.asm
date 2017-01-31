BITS 16
ORG 0X500				;Apperently we are loaded at 0x50:0x00

JMP _start

%INCLUDE "GDT.INC"		;Global Descriptor Tables
%INCLUDE "IO.INC"		;Input/Output Handlers

_start:
 CLI					;Clear Interrupts
 XOR AX,AX				;Null Segments
 MOV DS,AX
 MOV ES,AX
 MOV AX,0X9000			;Stack is at 0x9000-0xFFFF
 MOV SS,AX
 MOV SP,0XFFFF
 STI					;Restore Interupts
 
; MOV AL,'!'
; CALL PRINTCHAR16
 
 CALL LOAD_GDT			;Load the Global Descriptor Tables
 
 CLI					;Clear Interupts - DO NOT RE-ENABLE!
 MOV EAX,CR0			;Set Bit 0 in CR0 to Enter Protected Mode
 OR EAX,1
 MOV CR0,EAX
 
 JMP 08h:STAGE_THREE	;Properly Sets CS

;################;
;  Stage Three!  ;
;     32 Bits    ;
;################;

STAGE_THREE:
 MOV AX,0X10			;Set the Data Segments to Data Selector (0x10)
 MOV DS,AX
 MOV SS,AX
 MOV ES,AX
 MOV ESP,90000h			;Stack Starts at 90000h
 
 MOV AL,2
 OUT 0X92,AL
 
 
 ;Nothing More To Do, For Now.....
 
 CLI
 HLT
