# EXIST with MISP Auto-Installer

This script automatically installs the cyber threat information aggregation and analyzing system [EXIST](https://github.com/nict-csl/exist).  
This tool uses [misp-install-centos -7](https://github.com/vodkappa/misp-install-centos-7) to install MISP.

## System Requirements

- CentOS Linux release 7.7.1908 (Core)

## Usage
Run as root.
```
sudo su -
```
Install:
```
wget https://raw.githubusercontent.com/soji256/exist_with_misp_autoinstall/master/exist_with_misp_install.sh

chmod 755 exist_with_misp_install.sh
./exist_with_misp_install.sh
```
Configuration:
```
wget https://raw.githubusercontent.com/soji256/exist_with_misp_autoinstall/master/exist_with_misp_configuration.sh

# Set Your API keys
vim exist_with_misp_configuration.sh

chmod 755 exist_with_misp_configuration.sh
./exist_with_misp_configuration.sh
```
Access:
```
# EXIST
http://localhost:8000/

# MISP
http://localhost/
```

## EXIST
- nict-csl/exist: EXIST is a web application for aggregating and analyzing cyber threat intelligence.  
https://github.com/nict-csl/exist  

![EXIST](https://github.com/soji256/exist_with_misp_autoinstall/blob/master/img/exist.png "EXIST")

## MISP
- MISP/MISP: MISP (core software) - Open Source Threat Intelligence and Sharing Platform (formely known as Malware Information Sharing Platform)  
https://github.com/MISP/MISP  

![MISP](https://github.com/soji256/exist_with_misp_autoinstall/blob/master/img/misp.png "MISP")


# Update History 
- 2019/10/23 New "exist_with_misp_install.sh"
- 2019/10/24 New "exist_with_misp_configuration.sh"


Author: soji256 (Twitter @soji256)
