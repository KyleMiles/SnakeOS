BITS 16

LOAD_GDT:					;Load the Global Descriptor Table 
 CLI						;Clear Interupts
 PUSHA						;Save Regesters
  LGDT [GDT_INFO]			;Load GTD into GTDR (the register)
  STI						;Restore Interupts
 POPA						;Restore Registers
 RET

;#############################;
;   Global Descriptor Table   ;
;#############################;

_GDT:					;Null Descriptor
 DD 0
 DD 0
 
; Code
 DW 0FFFFh				;Limit Low
 DW 0					;Base Low
 DB 0					;Base Middle
 DB 10011010b			;Access
 DB 11001111b			;Granularity
 DB 0					;Base High
 
; Data
 DW 0FFFFh
 DW 0
 DB 0
 DB 10010010b
 DB 11001111b
 DB 0

END_GDT:
GDT_INFO:
 DW END_GDT - _GDT - 1
 DD _GDT
