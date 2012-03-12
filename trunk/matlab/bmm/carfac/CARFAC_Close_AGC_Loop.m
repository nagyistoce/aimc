% Copyright 2012, Google, Inc.
% Author Richard F. Lyon
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

function CF = CARFAC_Close_AGC_Loop(CF)
% function CF = CARFAC_Close_AGC_Loop(CF)

% fastest decimated rate determines interp needed:
decim1 = CF.AGC_params.decimation(1);

for mic = 1:CF.n_mics
  extra_damping = CF.AGC_state(mic).AGC_memory(:, 1);  % stage 1 result
  % Update the target stage gain for the new damping:
  new_g = CARFAC_Stage_g(CF.filter_coeffs(mic), extra_damping);
  % set the deltas needed to get to the new damping:
  CF.filter_state(mic).dzB_memory = ...
    (extra_damping - CF.filter_state(mic).zB_memory) / decim1;
  CF.filter_state(mic).dg_memory = ...
    (new_g - CF.filter_state(mic).g_memory) / decim1;
end