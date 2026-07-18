#include <stdint.h>

// `extern "C"` prevents C++ name mangling, allowing Dart to find the function by name.
extern "C" __attribute__((visibility("default"))) __attribute__((used))
int32_t initialize_ai_engine() {
    // Phase 1 placeholder: Later, this will initialize the threading pool,
    // detect RAM limits, and prep the GGUF runtime.
    return 1; // 1 = Success
}