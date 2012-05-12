% Copyright 2012, Google, Inc.
% Author: Richard F. Lyon
%
% This Matlab file is part of an implementation of Lyon's cochlear model:
% "Cascade of Asymmetric Resonators with Fast-Acting Compression"
% to supplement Lyon's upcoming book "Human and Machine Hearing"
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%     http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.

function [zY, state] = CARFAC_CAR_Step(x_in, CAR_coeffs, state)
% function [zY, state] = CARFAC_CAR_Step(x_in, CAR_coeffs, state)
%
% One sample-time update step for the filter part of the CARFAC.

% Most of the update is parallel; finally we ripple inputs at the end.

% Local nonlinearity zA and AGC feedback zB reduce pole radius:
zA = state.zA_memory;
zB = state.zB_memory + state.dzB_memory; % AGC interpolation
r1 = CAR_coeffs.r1_coeffs;
g = state.g_memory + state.dg_memory;  % interp g

% zB and zA are "extra damping", and multiply zr (compressed theta):
r = r1 - CAR_coeffs.zr_coeffs .* (zA + zB); 

% now reduce state by r and rotate with the fixed cos/sin coeffs:
z1 = r .* (CAR_coeffs.a0_coeffs .* state.z1_memory - ...
  CAR_coeffs.c0_coeffs .* state.z2_memory);
% z1 = z1 + inputs;
z2 = r .* (CAR_coeffs.c0_coeffs .* state.z1_memory + ...
  CAR_coeffs.a0_coeffs .* state.z2_memory);

% update the nonlinear function of "velocity", into zA:
zA = CARFAC_OHC_NLF(state.z2_memory - z2, CAR_coeffs);

zY = CAR_coeffs.h_coeffs .* z2;  % partial output

% Ripple input-output path, instead of parallel, to avoid delay...
% this is the only part that doesn't get computed "in parallel":
in_out = x_in;
for ch = 1:length(zY)
  % could do this here, or later in parallel:
  z1(ch) = z1(ch) + in_out;
  % ripple, saving final channel outputs in zY
  in_out = g(ch) * (in_out + zY(ch));
  zY(ch) = in_out;
end

% put new state back in place of old
% (z1 and z2 are genuine temps; the others can update by reference in C)
state.z1_memory = z1;
state.z2_memory = z2;
state.zA_memory = zA;
state.zB_memory = zB;
state.zY_memory = zY;
state.g_memory = g;

