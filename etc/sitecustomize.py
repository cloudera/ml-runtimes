# Copyright 2022 Cloudera. All Rights Reserved.
#
# This file is licensed under the Apache License Version 2.0
# (the "License"). You may not use this file except in compliance
# with the License. You may obtain  a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0.
#
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, either express or implied. Refer to the
# License for the specific permissions and limitations governing your
# use of the file.

import glob
import json
import os
import sys
import site

# Customize Python paths to respect conda environment in a user's
# home directory with the name python2.7.
#
# See: https://docs.python.org/3.3/tutorial/interpreter.html#the-customization-modules
home = os.path.expanduser("~")
version = sys.version_info
conda_env = os.path.join(home, ".conda", "envs", "python{0}.{1}".format(
    version[0], version[1]), "lib", "python{0}.{1}".format(version[0], version[1]), "site-packages")
# Insert conda environment before all global site packages but after everything else.
global_site_packages = site.getsitepackages()
global_site_packages_on_path = list(filter(lambda sp: sp in sys.path, global_site_packages))
if len(global_site_packages_on_path) > 0:
  min_global_site_package_index = min(sys.path.index(sp) for sp in global_site_packages_on_path)
  sys.path.insert(min_global_site_package_index, conda_env)

# Helper func to append first found file to sys.path if file exists with glob search
# If no files found then no change to sys.path
def append_first_glob(path, file):
  file_list = glob.glob(os.path.join(path, file))
  if file_list:
    sys.path.append(file_list[0])

# Check for the hadoop config file (set as a k8s config by CML operator) and extract
# the distro information to load the right pyspark module. Skip the pyspark setup if
# the engine is missing hadoop setup.
# Note: Runtimes are designed to be backward compatible with CML (older engines can
# work with latest CML) but not the other way around.
config_file = "/var/lib/cdsw/config/hadoop"
if os.path.isfile(config_file):
  with open(config_file) as filex:
    hadoop_config = json.load(filex)
  is_cloud = hadoop_config['isCloud']
  is_cdh_distro = hadoop_config['isCDHDistro']
  is_hdp_distro = hadoop_config['isHDPDistro']
  distro_dir = hadoop_config['distroDir']
  anaconda_dir = hadoop_config['anacondaDir']

  if is_cdh_distro:
    if os.path.exists(os.path.join(distro_dir, "SPARK2")):
      spark_parcel_path = os.path.join(distro_dir, "SPARK2")
      spark_name = "spark2"
    else:
      spark_parcel_path = os.path.join(distro_dir, "CDH")
      spark_name = "spark"
    sys.path.append(os.path.join(spark_parcel_path, "lib/%s/python" % (spark_name)))

  if is_hdp_distro:
    spark_home = os.path.join(distro_dir, "current", "spark2-client")
    if os.path.exists(spark_home):
      sys.path.append(os.path.join(spark_home, "python"))

  if is_cloud:
    if "SPARK_HOME" in os.environ:
      spark_home = os.environ["SPARK_HOME"]
      if os.path.exists(spark_home):
        sys.path.append(os.path.join(spark_home, "python"))
        append_first_glob(spark_home, "python/lib/pyspark*.zip")
        append_first_glob(spark_home, "python/lib/py4j-*.zip")

    if "HWC_HOME" in os.environ:
      hwc_home = os.environ["HWC_HOME"]
      if os.path.exists(hwc_home):
        append_first_glob(hwc_home, "pyspark_hwc-*.zip")

  if anaconda_dir and os.path.exists(anaconda_dir):
        sys.path.append(os.path.join(
            anaconda_dir, "lib/python{0}.{1}/site-packages".format(version[0], version[1])))
