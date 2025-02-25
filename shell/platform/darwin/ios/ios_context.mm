// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/ios_context.h"

#include "flutter/fml/logging.h"
#import "flutter/shell/platform/darwin/ios/ios_context_gl.h"
#import "flutter/shell/platform/darwin/ios/ios_context_software.h"

#if SHELL_ENABLE_METAL
#import "flutter/shell/platform/darwin/ios/ios_context_metal_impeller.h"
#import "flutter/shell/platform/darwin/ios/ios_context_metal_skia.h"
#endif  // SHELL_ENABLE_METAL

namespace flutter {

IOSContext::IOSContext() = default;

IOSContext::~IOSContext() = default;

std::unique_ptr<IOSContext> IOSContext::Create(IOSRenderingAPI api, IOSRenderingBackend backend) {
  switch (api) {
    case IOSRenderingAPI::kOpenGLES:
      return std::make_unique<IOSContextGL>();
    case IOSRenderingAPI::kSoftware:
      return std::make_unique<IOSContextSoftware>();
#if SHELL_ENABLE_METAL
    case IOSRenderingAPI::kMetal:
      switch (backend) {
        case IOSRenderingBackend::kSkia:
          return std::make_unique<IOSContextMetalSkia>();
        case IOSRenderingBackend::kImpeller:
          return std::make_unique<IOSContextMetalImpeller>();
      }
#endif  // SHELL_ENABLE_METAL
    default:
      break;
  }
  FML_CHECK(false);
  return nullptr;
}

IOSRenderingBackend IOSContext::GetBackend() const {
  return IOSRenderingBackend::kSkia;
}

}  // namespace flutter
