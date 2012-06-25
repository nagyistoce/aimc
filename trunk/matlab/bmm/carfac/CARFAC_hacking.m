% Copyright 2012 Google Inc. All Rights Reserved.
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

%% Test/demo hacking for CARFAC Matlab stuff:

clear variables

%%

use_plan_file = 1;
dB_list = -60:20:40

if use_plan_file
  
  file_signal = wavread('plan.wav');
  %   file_signal = file_signal(8100+(1:20000));  % trim for a faster test
  file_signal = file_signal(10000+(1:10000));  % trim for a faster test
  
else
  flist = 1400 + (1:4)*200;
  alist = [1, 1, 1, 1];
  sine_signal = 0;
  times = (0:9999)' / 22050;
  for fno = 1:length(flist)
    sine_signal = sine_signal + alist(fno)*sin(flist(fno)*2*pi*times);
  end
  growth_power = 0;  % use 0 for flat, 4 or more for near exponential
  file_signal = 1.0 * (sine_signal .* (times/max(times)).^growth_power);
end

% make a long test signal by repeating at different levels:
% dB = dB_list(1);
% test_signal =  10^(dB/20)* file_signal(1:4000) % lead-in [];
test_signal = [];
for dB =  dB_list
  test_signal = [test_signal; file_signal * 10^(dB/20)];
end


%% Run mono, then stereo test:

agc_plot_fig_num = 6;

for n_ears = 1:2
  
  CF_struct = CARFAC_Design(n_ears);  % default design
  
  if n_ears == 2
    % For the 2-channel pass, add a silent second channel:
    test_signal = [test_signal, zeros(size(test_signal))];
  end
  
  CF_struct = CARFAC_Init(CF_struct);
  
  [CF_struct, nap_decim, nap, BM, ohc, agc] = CARFAC_Run(CF_struct, test_signal, ...
    agc_plot_fig_num);
  
  %   nap = deskew(nap);  % deskew doesn't make much difference
  
  %   dB_BM = 10/log(10) * log(filter(1, [1, -0.995], BM(:, 20:50, :).^2));
  sm_BM = filter(1, [1, -0.995], BM(:, :, :).^2);
  
  % only ear 1:
  smoothed = sm_BM(100:100:end, :, 1);
  MultiScaleSmooth(10/log(10) * log(smoothed), 1);
  
 
  % Display results for 1 or 2 ears:
  for ear = 1:n_ears
    smooth_nap = nap_decim(:, :, ear);
    if n_ears == 1
      mono_max = max(smooth_nap(:));
    end
    figure(3 + ear + n_ears)  % Makes figures 5, ...
    image(63 * ((max(0, smooth_nap)/mono_max)' .^ 0.5))
    title('smooth nap from nap decim')
    colormap(1 - gray);
  end
  
  % Show resulting data, even though M-Lint complains:
  CF_struct
  CF_struct.ears(1).CAR_state
  CF_struct.ears(1).AGC_state
  min_max_decim = [min(nap_decim(:)), max(nap_decim(:))]
  
end

% Expected result:  Figure 3 looks like figure 2, a tiny bit darker.
% and figure 4 is empty (all zero)
