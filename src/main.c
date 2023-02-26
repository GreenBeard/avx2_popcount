#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define static_assert(expr, msg) _Static_assert(expr, msg)

#define BUFFER_SIZE (128 * 1024 * 1024)

extern size_t popcount_asm(void* buffer, size_t length);

uint32_t simd_popcount(void* buffer, size_t length) {
  assert((uintptr_t) buffer % (8 * 32) == 0);
  assert(length % (8 * 32) == 0);

  return popcount_asm(buffer, length / (8 * 32));
}

int main(int argc, char** argv) {
  void* buffer;
  int status;
  struct timespec start;
  struct timespec end;
  uint32_t milliseconds;

  status = posix_memalign(&buffer, 8 * 32, BUFFER_SIZE);
  assert(status == 0);
  assert(buffer != NULL);
  uint64_t simd_count;
  uint64_t expected_count;

  FILE* file = fopen("/dev/urandom", "r");
  size_t count = fread(buffer, BUFFER_SIZE, 1, file);
  assert(count == 1);
  fclose(file);
  //memset(buffer, 0xff, BUFFER_SIZE);

  clock_gettime(CLOCK_THREAD_CPUTIME_ID, &start);
  simd_count = simd_popcount(buffer, BUFFER_SIZE);
  clock_gettime(CLOCK_THREAD_CPUTIME_ID, &end);
  milliseconds = end.tv_sec - start.tv_sec + (end.tv_nsec - start.tv_nsec) / (1000 * 1000);
  printf("%u ms\n", milliseconds);

  clock_gettime(CLOCK_THREAD_CPUTIME_ID, &start);
  unsigned long* tmp = buffer;
  expected_count = 0;
  for (size_t i = 0; i < BUFFER_SIZE / sizeof(unsigned long); ++i) {
    expected_count += __builtin_popcountl(*tmp);
    ++tmp;
  }
  clock_gettime(CLOCK_THREAD_CPUTIME_ID, &end);
  milliseconds = end.tv_sec - start.tv_sec + (end.tv_nsec - start.tv_nsec) / (1000 * 1000);
  printf("%u ms\n", milliseconds);

  assert(expected_count == simd_count);

  return 0;
}
