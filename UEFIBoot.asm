;############################;
;                            ;
;   UEFIBoot.asm 2.0         ;
;    - My First Bootloader   ;
;                            ;
;	SnakeOS                  ;
;    - Kyle Martin           ;
;                            ;
;############################;

;Disk Layout Levels (ONE LEVEL = 512 BYTES):
; 0:  Protective MBR
; 1:  Primary GPT Header
; 2:  Entries 1-4
; 3:  Entries 5-128
; 34: Partitions
;-34: End Of Partitions
;-33: Entries 1-4
;-2:  Entries 5-128
;-1:  Secondary GPT Header

;================Protective MBR==============;
 ; Bootstrap Code Area (446 BYTES):
  times 445-($-$$) DB 0

 ; Protective Partition Table Entries:
  ; Unbootable First Sector
   DB 0x00
  ; Starting Location Of This Partition (CHS/LBA Hybrid Weirdness):
   DB 0x00, 0x02, 0x00
  ; Partition ID:
   DB 0xEE					; Protective MBR
  ; Ending Location Of This Partition (CHS/LBA Hybrid Weirdness):
   DB 0xFF, 0xFF, 0xFF
  ; Starting LBA (LBA of GPT Partition Header)
   DD 1
  ; Size of that LBA
   DD 0xFFFFFFFF
 
 ;Buffer to Fill Partition Area:
 times 510-($-$$) DB 0
 DB 0x55
 DB 0xAA

;==================GPT Header================;

 ; EFI Signature ("EFI PART"):
  DB "EFI PART"
  
 ; EFI Version Number
  DB 00h
  DB 00h
  DB 01h
  DB 00h
  
 ; Header Size (92 bytes)
  DB 0x5C
  DB 0x00
  DB 0x00
  DB 0x00
  
 ; CRC32 
  DD 0
  
 ; Reserved
  DD 0
 ; Current LBA
  DQ 1
 ; Backup LBA
  DQ 37
 ; First LBA
  DQ 34
 ; Last LBA
  DQ 35
  
 ; Disk GUID
  DB 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12
 
 ; LBA Partition Entry Start
  DQ 2
 ; Number of Partion Entries
  DW 128
 ; Partition Entry Size
  DW 128
 ; CRC32 of Partiotion Array
  DD 0

 times 1024-($-$$) DB 0

;===============Partition Entry 1============;

 ; 16-Byte Partition Type GUID
  DDQ 0x28732AC11FF8D211BA4B00A0C93EC93B
  
 ; 16-Byte Partition GUID
  DDQ 0x28732AC11FF8D211BA4B00A0C93EC93A

 ; Starting LBA
  DQ 34
 ; Ending LBA
  DQ 34
 ; Partition Attributes
  DQ 0
  
 ; Partition Name
  NAME1: DW 0x3600, 0x7E00, 0x7100, 0x7B00, 0x7500, 0x5F00, 0x6300
  TIMES 36-($-NAME1) DW 0x0000

;===============Partition Entry 2============;

 ; 16-Byte Partition Type GUID
  DDQ 0xA2A0D0EBE5B9334487C068B6B72699C7
  
 ; 16-Byte Partition GUID
  DDQ 0x28732AC11FF8D211BA4B00A0C93EC939

 ; Starting LBA
  DQ 35
  
 ; Ending LBA
  DQ 35

 ; Partition Attributes
  DQ 0
  
 ; Partition Name
  NAME2: DW 0x5D00, 0x7100, 0x7900, 0x7E00
  TIMES 36-($-NAME2) DW 0x0000

;===============Partition Entry 3============;
  NAME3:
  TIMES 128-($-NAME3) DB 0x00
  
;===============Partition Entry 4============;
  NAME4:
  TIMES 128-($-NAME4) DB 0x00



