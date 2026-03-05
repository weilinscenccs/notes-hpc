#! /bin/bash
app_path=/opt

# install aocc compiler
install_aocc()
{
  aocc_version=5.1.0
  local tmp=$( mktemp -d )
  echo tmp="$tmp"
  aocc_path=$app_path/amd/aocc
  cd $tmp && \
  wget https://download.amd.com/developer/eula/aocc/aocc-5-1/aocc-compiler-${aocc_version}.tar && \
  mkdir -p $app_path/amd/aocc && \
  tar xf aocc-compiler-${aocc_version}.tar -C $aocc_path && \
  mv $app_path/amd/aocc/aocc-compiler-${aocc_version} $aocc_path/$aocc_version && \
  [[ $_clean -eq 1 ]] && rm -rf $tmp
}

# intel-oneapi-mkl
intelmkl_url=https://registrationcenter-download.intel.com/akdlm/IRC_NAS/6a17080f-f0de-41b9-b587-52f92512c59a/intel-onemkl-2025.3.1.11_offline.sh
intelmkl_sha384=79486367329706fc7267843c49cac3f93243b75d292426205cfad4162df0a3ffd6613d18a32df64193fc97cec1d94b22
intelmkl_version=2025.3.1.11

intelcpp_version=2025.3.1.16
intelcpp_url=https://registrationcenter-download.intel.com/akdlm/IRC_NAS/5adfc398-db78-488c-b98f-78461b3c5760/intel-dpcpp-cpp-compiler-2025.3.1.16_offline.sh
intelcpp_sha256=b0e8920fa390302133b0e92784389ae383806d8414c48ae8b9e2f2ed1ad72471

intelftn_version=2025.3.1.16
intelftn_url=https://registrationcenter-download.intel.com/akdlm/IRC_NAS/724303ca-6927-4327-a560-e0aabb55b010/intel-fortran-compiler-2025.3.1.16_offline.sh
intelftn_sha256=13138cca7df96469d7f707428de6e2cf23a98a49ac01ea0b80c7623c0f474d43

intelhpckit_url=https://registrationcenter-download.intel.com/akdlm/IRC_NAS/f59a79aa-4a6e-46e8-a6c2-be04bb13f274/intel-oneapi-hpc-toolkit-2025.3.1.55_offline.sh
intelhpckit_sha384=9cebc5945370287d14c5ca18a585561157e0cc5ead771504f5f00c2dd0d4a60b73f99dc8ef8b8804257f7bbe067c60a7
intelhpckit_version=2025.3.1.55
intelhpckit_deb="g++ libatspi2.0-0 libdrm2 libgbm1 libglib2.0-bin libgtk-3-0 libnotify4 libnss3 libxcb-dri3-0 xdg-utils"

intelcppkit_url=https://registrationcenter-download.intel.com/akdlm/IRC_NAS/5c1dffad-02fa-414d-bfb9-d86a99998ad7/intel-cpp-essentials-2025.3.1.26_offline.sh
intelcppkit_sha384=152378eff1415255929c5f00f02760535438580f599725a4b8fb5e6b7f24ac018fbc5e2fb30f5d2932b73ab045420892
intelcppkit_version=2025.3.1.26

intelftnkit_url=https://registrationcenter-download.intel.com/akdlm/IRC_NAS/ce0f9b00-4780-483f-bc09-96d6fb4467ca/intel-fortran-essentials-2025.3.1.26_offline.sh
intelftnkit_sha384=65bb09b909798e59aaf956d9b7d95fb995bc05c4015de821c8cf93c84c9b3498451450a368721eeddb2c2a21add7d4ca
intelftnkit_version=2025.3.1.26

install_intel()
{
  local intel_url=$1
  local intel_sha=$2
  local intel_version=$3
  local tmp=$( mktemp -d )
  echo tmp="$tmp"
  local intel_path=$app_path/intel/compiler/$intel_version
  cd $tmp && \
  wget $intel_url && \
  echo "$intel_sha $(basename $intel_url)" | ${shacmd:-sha384sum} -c --quiet && \
  bash ./$(basename $intel_url) -a -s --eula accept --install-dir=$intel_path
  [[ $_clean -eq 1 ]] && rm -rf $tmp
}

install_slurm()
{
  # when building docker image:
    # work on 22.04 but not on 24.04 (need much more work on the docker itself)
    # SLURM_RUN_AS=root
    # no systemctl in Ubuntu docker image you need start the service yourself
  # on host machine, ok both 22.04 & 24.04
apt-get update ;\
  DEBIAN_FRONTEND="noninteractive" TZ="Europe/Stockholm" apt-get install -y \
  munge mariadb-client mariadb-server libmariadb-dev \
  slurm-client slurm-wlm-basic-plugins slurmdbd slurmd slurmctld libpmix-dev dbus
echo "APT INSTALL DONE"

# echo mysql_install_db ...
# mysql_install_db --user=mysql --datadir=/var/lib/mysql

echo  Setup Munge
dd if=/dev/urandom bs=1 count=1024 >/etc/munge/munge.key
chown munge:munge /etc/munge/munge.key
chmod 600 /etc/munge/munge.key
echo  Setup Munge done

# Setup Slurm environment
# cp cgroup.conf /etc/slurm
cp slurm.conf    /etc/slurm/slurm.conf
cp slurmdbd.conf /etc/slurm/slurmdbd.conf
grep -q 24 /etc/issue && sed -i 's/cons_res/cons_tres/' /etc/slurm/slurm.conf
sed -i "s/SlurmUser=.*/SlurmUser=${SLURM_RUN_AS:-slurm}/" /etc/slurm/slurm.conf
sed -i "s/StorageUser=.*/StorageUser=${SLURM_RUN_AS:-slurm}/" /etc/slurm/slurmdbd.conf
mkdir -p /var/run/slurm 
mkdir -p /var/log/slurm 
mkdir -p /var/lib/slurm/slurmctld
chown -R slurm:slurm /etc/slurm/slurmdbd.conf
chown -R slurm:slurm /var/lib/slurm
chown -R slurm:slurm /var/log/slurm
chown -R slurm:slurm /var/run/slurm
chmod 755 /var/lib/slurm/slurmctld
chmod 755 /var/run/slurm
chmod 600 /etc/slurm/slurmdbd.conf

systemctl start mysqld
until systemctl is-active --quiet mysqld; do
    echo "Waiting for mysqld service..."
    sleep 1
done

until mysqladmin ping -u root --silent; do
    echo "Waiting for MySQL to accept connections..."
    sleep 1
done
echo "MySQL is fully ready!"
mysql -u root <<-EOSQL
    CREATE DATABASE IF NOT EXISTS slurm_acct_db;
    CREATE USER IF NOT EXISTS 'slurm'@'localhost' IDENTIFIED BY 'slurmdbpass';
    GRANT USAGE ON *.* TO 'slurm'@'localhost';
    GRANT ALL PRIVILEGES ON slurm_acct_db.* TO 'slurm'@'localhost';
    FLUSH PRIVILEGES;
EOSQL
echo "slurm_acct_db created!"

systemctl start munge
systemctl start slurmdbd
systemctl start slurmctld
systemctl start slurmd
}

## tools
apt update ; apt install -y build-essential automake autoconf libtool pkg-config gfortran cmake gawk parallel git bc wget curl htop lmod

## slurm queue
install_slurm

## amd aocc compiler
install_aocc

## everything intel, maybe too much
# install_intel $intelhpckit_url $intelhpckit_sha384 $intelhpckit_version ; apt install $intelhpckit_deb

## chose 1 of these 2 kits or both
# install_intel $intelcppkit_url $intelcppkit_sha384 $intelcppkit_version # c cpp + mkl
install_intel $intelftnkit_url $intelftnkit_sha384 $intelftnkit_version # fortran mkl mpi
find /opt/intel -name "ifx"

## chose mkl + intelftn or mkl + intelcpp, or all of three
# install_intel $intelmkl_url $intelmkl_sha384 $intelmkl_version
# shacmd=sha256sum install_intel $intelftn_url $intelftn_sha256 $intelftn_version
# shacmd=sha256sum install_intel $intelcpp_url $intelcpp_sha256 $intelcpp_version
