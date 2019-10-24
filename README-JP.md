# EXIST with MISP Auto-Installer

このスクリプトは「サイバー脅威情報集約システム EXIST」と MISP を自動インストールするためのスクリプトです。  
構築用スクリプトと各種APIとの連携設定用スクリプトという2つのスクリプトで構成されています。  
なお、MISP のインストールには [misp-install-centos -7](https://github.com/vodkappa/misp-install-centos-7) を利用しています。

## 必要環境
新規にインストールされた CentOS 7 を前提としています。

- CentOS Linux release 7.7.1908 (Core)

## 利用方法
以降のコマンドは root として実行します。
```
sudo su -
```
インストール:
```
wget https://raw.githubusercontent.com/soji256/exist_with_misp_autoinstall/master/exist_with_misp_install.sh

chmod 755 exist_with_misp_install.sh
./exist_with_misp_install.sh
```
各種設定:
```
wget https://raw.githubusercontent.com/soji256/exist_with_misp_autoinstall/master/exist_with_misp_configuration.sh

# 各種 API key をスクリプトの所定の欄に記載してから実行してください。
vim exist_with_misp_configuration.sh

chmod 755 exist_with_misp_configuration.sh
./exist_with_misp_configuration.sh
```
アクセス方法:
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


## 更新履歴 
- 2019/10/23 新規作成 "exist_with_misp_install.sh"
- 2019/10/24 新規作成 "exist_with_misp_configuration.sh"


著者: soji256 (Twitter [@soji256](https://twitter.com/soji256))
