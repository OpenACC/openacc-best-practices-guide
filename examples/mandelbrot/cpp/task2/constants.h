/*
 *  Copyright 2014 NVIDIA Corporation
 *  
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *  
 *      http://www.apache.org/licenses/LICENSE-2.0
 *  
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */
const unsigned int WIDTH=16384;
const unsigned int HEIGHT=16384;
const unsigned int MAX_ITERS=50;
const unsigned int MAX_COLOR=255;
const double xmin=-1.7;
const double xmax=.5;
const double ymin=-1.2;
const double ymax=1.2;
const double dx=(xmax-xmin)/WIDTH;
const double dy=(ymax-ymin)/HEIGHT;
