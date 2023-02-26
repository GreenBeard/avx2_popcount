default rel

; todo see if vpsrlw, or vpsrldq is faster
; well they appear to be the same size, and speed
%define USE_BYTE_SHIFT 1

; This is a helper macro for computing popcount
; the even registers hold the partial results
%macro ymm_sum_helper 0
  vpaddw ymm0, ymm0, ymm1
  vpaddw ymm2, ymm2, ymm3
  vpaddw ymm4, ymm4, ymm5
  vpaddw ymm6, ymm6, ymm7
  vpaddw ymm8, ymm8, ymm9
  vpaddw ymm10, ymm10, ymm11
  vpaddw ymm12, ymm12, ymm13
  vpaddw ymm14, ymm14, ymm15
%endmacro

SECTION .data

a0: db 0x55
a1: db 0x33
a2: db 0x0f

SECTION .text
global popcount_asm

; void* buffer - rdi
; uint64_t chunk count - rsi (r6)
; returns uint64_t
popcount_asm:
  push r12
  push r13
  push r14
  xor rax, rax
  mov rcx, rsi

.loop:
  lea r8, [rdi + 1 * 32]
  lea r9, [rdi + 2 * 32]
  lea r10, [rdi + 3 * 32]
  lea r11, [rdi + 4 * 32]
  lea r12, [rdi + 5 * 32]
  lea r13, [rdi + 6 * 32]
  lea r14, [rdi + 7 * 32]
  vmovdqa ymm0, [rdi]
  vmovdqa ymm2, [r8]
  vmovdqa ymm4, [r9]
  vmovdqa ymm6, [r10]
  vmovdqa ymm8, [r11]
  vmovdqa ymm10, [r12]
  vmovdqa ymm12, [r13]
  vmovdqa ymm14, [r14]

  ; garbage can be left at registers at times. I think I should draw out which
  ; bits are useful, zero, or noise at each step. Also I need to finish the last
  ; bits (up to 128 instead of just 8).

  ; v indicates useful bits
  ; 0 indicates zero bits
  ; x indicates garbage bits

  vpbroadcastb ymm15, [a0]
  vpand ymm1, ymm0, ymm15
  vpand ymm3, ymm2, ymm15
  vpand ymm5, ymm4, ymm15
  vpand ymm7, ymm6, ymm15
  vpand ymm9, ymm8, ymm15
  vpand ymm11, ymm10, ymm15
  vpand ymm13, ymm12, ymm15
  vpand ymm15, ymm14, ymm15
  vpxor ymm0, ymm0, ymm1
  vpxor ymm2, ymm2, ymm3
  vpxor ymm4, ymm4, ymm5
  vpxor ymm6, ymm6, ymm7
  vpxor ymm8, ymm8, ymm9
  vpxor ymm10, ymm10, ymm11
  vpxor ymm12, ymm12, ymm13
  vpxor ymm14, ymm14, ymm15
  vpsrlw ymm0, ymm0, 1
  vpsrlw ymm2, ymm2, 1
  vpsrlw ymm4, ymm4, 1
  vpsrlw ymm6, ymm6, 1
  vpsrlw ymm8, ymm8, 1
  vpsrlw ymm10, ymm10, 1
  vpsrlw ymm12, ymm12, 1
  vpsrlw ymm14, ymm14, 1
  ymm_sum_helper
  ; [... vv vv vv vv]

  vpbroadcastb ymm15, [a1]
  vpand ymm1, ymm0, ymm15
  vpand ymm3, ymm2, ymm15
  vpand ymm5, ymm4, ymm15
  vpand ymm7, ymm6, ymm15
  vpand ymm9, ymm8, ymm15
  vpand ymm11, ymm10, ymm15
  vpand ymm13, ymm12, ymm15
  vpand ymm15, ymm14, ymm15
  vpxor ymm0, ymm0, ymm1
  vpxor ymm2, ymm2, ymm3
  vpxor ymm4, ymm4, ymm5
  vpxor ymm6, ymm6, ymm7
  vpxor ymm8, ymm8, ymm9
  vpxor ymm10, ymm10, ymm11
  vpxor ymm12, ymm12, ymm13
  vpxor ymm14, ymm14, ymm15
  vpsrlw ymm0, ymm0, 2
  vpsrlw ymm2, ymm2, 2
  vpsrlw ymm4, ymm4, 2
  vpsrlw ymm6, ymm6, 2
  vpsrlw ymm8, ymm8, 2
  vpsrlw ymm10, ymm10, 2
  vpsrlw ymm12, ymm12, 2
  vpsrlw ymm14, ymm14, 2
  ymm_sum_helper
  ; [... 0vvv 0vvv]

  vpbroadcastb ymm15, [a2]
  vpand ymm1, ymm0, ymm15
  vpand ymm3, ymm2, ymm15
  vpand ymm5, ymm4, ymm15
  vpand ymm7, ymm6, ymm15
  vpand ymm9, ymm8, ymm15
  vpand ymm11, ymm10, ymm15
  vpand ymm13, ymm12, ymm15
  vpand ymm15, ymm14, ymm15
  vpxor ymm0, ymm0, ymm1
  vpxor ymm2, ymm2, ymm3
  vpxor ymm4, ymm4, ymm5
  vpxor ymm6, ymm6, ymm7
  vpxor ymm8, ymm8, ymm9
  vpxor ymm10, ymm10, ymm11
  vpxor ymm12, ymm12, ymm13
  vpxor ymm14, ymm14, ymm15
  vpsrlw ymm0, ymm0, 4
  vpsrlw ymm2, ymm2, 4
  vpsrlw ymm4, ymm4, 4
  vpsrlw ymm6, ymm6, 4
  vpsrlw ymm8, ymm8, 4
  vpsrlw ymm10, ymm10, 4
  vpsrlw ymm12, ymm12, 4
  vpsrlw ymm14, ymm14, 4
  ymm_sum_helper
  ; [... 0000vvvv]

%if USE_BYTE_SHIFT
  vpsrldq ymm1, ymm0, 1
  vpsrldq ymm3, ymm2, 1
  vpsrldq ymm5, ymm4, 1
  vpsrldq ymm7, ymm6, 1
  vpsrldq ymm9, ymm8, 1
  vpsrldq ymm11, ymm10, 1
  vpsrldq ymm13, ymm12, 1
  vpsrldq ymm15, ymm14, 1
%else
  vpsrlw ymm1, ymm0, 8
  vpsrlw ymm3, ymm2, 8
  vpsrlw ymm5, ymm4, 8
  vpsrlw ymm7, ymm6, 8
  vpsrlw ymm9, ymm8, 8
  vpsrlw ymm11, ymm10, 8
  vpsrlw ymm13, ymm12, 8
  vpsrlw ymm15, ymm14, 8
%endif
  ymm_sum_helper
  ; [... 000xxxxx000vvvvv]

%if USE_BYTE_SHIFT
  vpsrldq ymm1, ymm0, 2
  vpsrldq ymm3, ymm2, 2
  vpsrldq ymm5, ymm4, 2
  vpsrldq ymm7, ymm6, 2
  vpsrldq ymm9, ymm8, 2
  vpsrldq ymm11, ymm10, 2
  vpsrldq ymm13, ymm12, 2
  vpsrldq ymm15, ymm14, 2
%else
  vpsrld ymm1, ymm0, 16
  vpsrld ymm3, ymm2, 16
  vpsrld ymm5, ymm4, 16
  vpsrld ymm7, ymm6, 16
  vpsrld ymm9, ymm8, 16
  vpsrld ymm11, ymm10, 16
  vpsrld ymm13, ymm12, 16
  vpsrld ymm15, ymm14, 16
%endif
  ymm_sum_helper
  ; [... 00xxxxxx00xxxxxx00xxxxxx00vvvvvv]

%if USE_BYTE_SHIFT
  vpsrldq ymm1, ymm0, 4
  vpsrldq ymm3, ymm2, 4
  vpsrldq ymm5, ymm4, 4
  vpsrldq ymm7, ymm6, 4
  vpsrldq ymm9, ymm8, 4
  vpsrldq ymm11, ymm10, 4
  vpsrldq ymm13, ymm12, 4
  vpsrldq ymm15, ymm14, 4
%else
  vpsrlq ymm1, ymm0, 4
  vpsrlq ymm3, ymm2, 4
  vpsrlq ymm5, ymm4, 4
  vpsrlq ymm7, ymm6, 4
  vpsrlq ymm9, ymm8, 4
  vpsrlq ymm11, ymm10, 4
  vpsrlq ymm13, ymm12, 4
  vpsrlq ymm15, ymm14, 4
%endif
  ymm_sum_helper
  ; [... ...0xxxxxxx0xxxxxxx0xxxxxxx0vvvvvvv]

  vpsrldq ymm1, ymm0, 8
  vpsrldq ymm3, ymm2, 8
  vpsrldq ymm5, ymm4, 8
  vpsrldq ymm7, ymm6, 8
  vpsrldq ymm9, ymm8, 8
  vpsrldq ymm11, ymm10, 8
  vpsrldq ymm13, ymm12, 8
  vpsrldq ymm15, ymm14, 8
  ymm_sum_helper
  ; [... ...xxxxxxxxxxxxxxxxxxxxxxxxvvvvvvvv]
  vpxor ymm15, ymm15
  mov r8d, 0xff
  pinsrb xmm15, r8d, 0
  vinserti128 ymm15, ymm15, xmm15, 1
  vpand ymm0, ymm0, ymm15
  vpand ymm2, ymm2, ymm15
  vpand ymm4, ymm4, ymm15
  vpand ymm6, ymm6, ymm15
  vpand ymm8, ymm8, ymm15
  vpand ymm10, ymm10, ymm15
  vpand ymm12, ymm12, ymm15
  vpand ymm14, ymm14, ymm15
  vextracti128 xmm1, ymm0, 1
  vextracti128 xmm3, ymm2, 1
  vextracti128 xmm5, ymm4, 1
  vextracti128 xmm7, ymm6, 1
  vextracti128 xmm9, ymm8, 1
  vextracti128 xmm11, ymm10, 1
  vextracti128 xmm13, ymm12, 1
  vextracti128 xmm15, ymm14, 1
  paddw xmm0, xmm1
  paddw xmm2, xmm3
  paddw xmm4, xmm5
  paddw xmm6, xmm7
  paddw xmm8, xmm9
  paddw xmm10, xmm11
  paddw xmm12, xmm13
  paddw xmm14, xmm15
  ; there are some garbage bits in the upper half of the ymm registers which don't matter
  ; [... ...0000000vvvvvvvvv]

  paddw xmm0, xmm2
  paddw xmm4, xmm6
  paddw xmm8, xmm10
  paddw xmm12, xmm14

  paddw xmm0, xmm4
  paddw xmm8, xmm12

  paddw xmm0, xmm8

  pextrw esi, xmm0, 0
  add rax, rsi
  lea rdi, [rdi + 8 * 32]
  dec rcx
  jnz .loop

exit:
  pop r14
  pop r13
  pop r12
  ret
