###
# SGA Shared Canvas v@VERSION
#
# **SGA Shared Canvas** is a shared canvas reader written in CoffeeScript.
#
# Date: @DATE
#
# (c) Copyright University of Maryland 2012-2013.  All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
###

(($, MITHgrid) ->
  #
  # The application uses the SGA.Reader namespace.
  #
  # N.B.: This may change as we move towards a general component
  # repository for MITHgrid. At that point, we'll refactor out the
  # general purpose components and keep the SGA namespace for code
  # specific to the SGA project.
  #
  MITHgrid.globalNamespace "SGA"
  SGA.namespace "Reader", (SGAReader) ->
