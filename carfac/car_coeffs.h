//
//  car_coeffs.h
//  CARFAC Open Source C++ Library
//
//  Created by Alex Brandmeyer on 5/10/13.
//
// This C++ file is part of an implementation of Lyon's cochlear model:
// "Cascade of Asymmetric Resonators with Fast-Acting Compression"
// to supplement Lyon's upcoming book "Human and Machine Hearing"
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#ifndef CARFAC_Open_Source_C__Library_CARCoeffs_h
#define CARFAC_Open_Source_C__Library_CARCoeffs_h

#include "car_params.h"

// TODO (alexbrandmeyer): check that struct is ok given possible non-triviality
// of the 'Design' method. A change to class would require the addition of
// accessor functions.
struct CARCoeffs {
  void Design(const CARParams& car_params, const FPType fs,
              const FloatArray& pole_freqs);
  int n_ch_;
  FPType velocity_scale_;
  FPType v_offset_;
  FloatArray r1_coeffs_;
  FloatArray a0_coeffs_;
  FloatArray c0_coeffs_;
  FloatArray h_coeffs_;
  FloatArray g0_coeffs_;
  FloatArray zr_coeffs_;
};

#endif