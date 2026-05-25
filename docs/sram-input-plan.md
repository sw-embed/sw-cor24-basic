# SRAM Program Input

Add SRAM-based program input to the BASIC interpreter so that large
.bas files can be pre-loaded at address 0x040000 and read at startup,
switching to UART on NUL byte. Unblocks Smalltalk BASIC-hosted compiler.

## Steps

1. Implement SRAM source reading in basic_io unit — add sp/sm globals,
   modify read_line to read from PEEK(sp) when sm=1, switch to UART on NUL.
2. Test and validate — rebuild basic.p24, verify existing tests pass
   (zero at 0x040000 = immediate UART fallback), test with a .bas file
   loaded via --load-binary.
