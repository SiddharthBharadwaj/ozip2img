#!/bin/bash

clear
CURR_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
tools=$CURR_DIR/tools
packages='python3 python python3-pip brotli'

Green='\033[0;32m'
NC='\033[0m'

for pkg in ${packages[@]}; do
    is_pkg_installed=$(dpkg-query -W --showformat='${Status}\n' ${pkg} | grep "install ok installed")
    if [ "${is_pkg_installed}" == "install ok installed" ]; then
        echo -e "Checking for $pkg: ${Green}${pkg} is installed.${NC}"
    else
      sudo apt-get install $packages
    fi
done

pip3 install -r $tools/oppo_ozip_decrypt/requirements.txt &> /dev/null

sleep 2
clear

read -p $'\e[31mEnter Ozip Path\e[0m: ' opath
read -p $'\e[31mSelect One Of The Below\e[0m
1. system
2. vendor
3. both
>> ' file

echo -e "${Green}Creating temp directory${NC}"
mkdir $CURR_DIR/temp
tmp=$CURR_DIR/temp
echo -e "${Green}Copying Ozip to temp ..........${NC}"
cp -r $opath $tmp
echo -e "${Green}Done !!${NC}"
echo -e "${Green}Decrypting & Extracting Ozip ..........${NC}"
python $tools/oppo_ozip_decrypt/ozipdecrypt.py $tmp/*ozip &> /dev/null
echo -e "${Green}Done !!${NC}"

system () {
  echo -e "${Green}Converting Brotli Image ..........${NC}"
  brotli --decompress $tmp/out/system.new.dat.br &> /dev/null
  echo -e "${Green}Done !!${NC}"
  echo -e "${Green}Creating IMG ..........${NC}"
  python $tools/sdat2img.py  $tmp/out/system.transfer.list  $tmp/out/system.new.dat system.img
}
vendor () {
  echo -e "${Green}Converting Brotli Image ..........${NC}"
  brotli --decompress $tmp/out/vendor.new.dat.br &> /dev/null
  echo -e "${Green}Done !!${NC}"
  echo -e "${Green}Creating IMG ..........${NC}"
  python $tools/sdat2img.py  $tmp/out/vendor.transfer.list  $tmp/out/vendor.new.dat vendor.img
}

if [ "$file" == "1" ] || [ "$file" == "system" ]; then
  system
elif [ "$file" == "2" ] || [ "$file" == "vendor" ]; then
  vendor
elif [ "$file" == "3" ] || [ "$file" == "both" ]; then
  echo -e "${Green}Creating System Image ..........${NC}"
  system
  echo -e "${Green}Creating Vendor Image ..........${NC}"
  vendor
fi
echo -e "${Green}Task Completed !!${NC}"
rm -rf $tmp
