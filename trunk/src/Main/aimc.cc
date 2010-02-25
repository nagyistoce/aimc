// Copyright 2008-2010, Thomas Walters
//
// AIM-C: A C++ implementation of the Auditory Image Model
// http://www.acousticscale.org/AIMC
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

#include <stdlib.h>

#include <string>

#include "Modules/Input/ModuleFileInput.h"
#include "Modules/BMM/ModuleGammatone.h"
#include "Modules/BMM/ModulePZFC.h"
#include "Modules/NAP/ModuleHCL.h"
#include "Modules/Strobes/ModuleParabola.h"
#include "Modules/SAI/ModuleSAI.h"
#include "Modules/SSI/ModuleSSI.h"
#include "Modules/Profile/ModuleSlice.h"
#include "Modules/Profile/ModuleScaler.h"
#include "Modules/Features/ModuleGaussians.h"
#include "Modules/Output/FileOutputHTK.h"

int main(int argc, char* argv[]) {
  aimc::Parameters params;

  int buffer_length = 480;
  params.SetInt("input.buffersize", buffer_length);
  params.SetBool("slice.normalize", true);
  params.SetFloat("nap.lowpass_cutoff", 100.0f);

  aimc::ModuleFileInput input(&params);
  aimc::ModuleGammatone bmm(&params);
  // aimc::ModulePZFC bmm(&params);
  aimc::ModuleHCL nap(&params);
  // aimc::ModuleParabola strobes(&params);
  // aimc::ModuleSAI sai(&params);
  // aimc::ModuleSSI ssi(&params);
  aimc::ModuleSlice profile(&params);
  aimc::ModuleScaler scaler(&params);
  aimc::ModuleGaussians features(&params);
  aimc::FileOutputHTK output(&params);

  std::string parameters_string = params.WriteString();
  printf("%s", parameters_string.c_str());

  input.AddTarget(&bmm);
  bmm.AddTarget(&nap);
  nap.AddTarget(&profile);
  //strobes.AddTarget(&sai);
  //sai.AddTarget(&ssi);
  //ssi.AddTarget(&profile);
  profile.AddTarget(&scaler);
  scaler.AddTarget(&features);
  features.AddTarget(&output);

  float frame_period_ms = 1000.0f * buffer_length
                          / input.GetOutputBank()->sample_rate();

  output.OpenFile("test_output.htk", frame_period_ms);
  if (input.LoadFile("test.wav")) {
    input.Process();
  } else {
    printf("LoadFile failed");
  }

  input.Reset();
  output.OpenFile("test_output_2.htk", frame_period_ms);
  if (input.LoadFile("test.wav")) {
    input.Process();
  } else {
    printf("LoadFile failed");
  }
}