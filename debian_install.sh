#!/usr/bin/env bash
# 2020 - Douglas Berdeaux (WeakNetLabs@Gmail.com)
# OWL installer script
printf "\n  WeakNet Labs - (c) GNU 2020 \n  OWL Installer Script\n\n"
# Functions:
getDbPass () {
  printf "[*] Please give me a new password for your OWASP-LAB database: \n"
  read -s dbpass
  printf "[*] Confirm the password: \n"
  read -s dbpassconf
  if [[ "$dbpass" != "$dbpassconf" ]]
    then
      printf "[!] Passwords do not match, please try again: \n"
      getDbPass
  else # set the password inthe config
    sed -i "s/OWLPASS/$dbpass/" /var/www/html/owasp-lab/config.php
    # set the password in the database itself:
    mysql -D owasp_lab -e "grant all on owasp_lab.* to 'owasp_lab_usr'@'localhost' identified by '$dbpass'"
    printf "[*] Showing grants for 'owasp_lab_usr'@'localhost' ... \n"
    mysql -e "show grants for 'owasp_lab_usr'@'localhost'"
  fi # else we are OK to continue.

}
export f getDbPass # to be used anywhere
# Workflow:
printf "[*] Updating repositories ... \n"
apt update > /dev/null 2>&1
printf "[*] Installing Apache2 web server ... \n"
apt install -y apache2 apache2-utils > /dev/null 2>&1
apache2 -v
printf "[*] Installing MariaDB (MySQL) client and server ... \n"
apt install -y mariadb-server mariadb-client > /dev/null 2>&1
printf "[*] Installing PHP ... \n"
export PHPVER=$(apt search php 2>/dev/null |sed 's/\/.*//' | egrep -E '^php[0-9]\.?[0-9]?$')
if [[ "$PHPVER" == "" ]]
  then
    printf "[!] Could not determine the latest version of PHP from your repository! \n"
  else # we got the version OK:
    printf "[*] Current PHP available in repository: $PHPVER ... \n"
    apt install $PHPVER libapache2-mod-$PHPVER $PHPVER-mysql php-common \
    $PHPVER-cli $PHPVER-common $PHPVER-json $PHPVER-opcache $PHPVER-readline -y > /dev/null 2>&1
fi
printf "[*] Restarting Apache2 ... \n"
systemctl restart apache2
printf "[*] Installing OWASP-Lab into web server ... \n"
mkdir /var/www/html/owasp-lab
cp -R * /var/www/html/owasp-lab/ # copy files into new site
printf "[*] Creating database, \"owasp_lab\" ... \n";
mysql -e "create database owasp_lab"
# now update the database:
getDbPass
printf "[*] Setting up database using data_model.sql file ... \n"
mysql -D owasp_lab < data_model.sql
printf "[*] Verifying newly created test data ... \n"
if [[ "$(mysql -s -D owasp_lab -e "select count(*) from blog"|egrep -E '^[0-9]')" -ne 3 ]]
then
  printf "[!] Something went wrong with the data insert! \n"
  exit 1337;
else
  printf "[*] Installation completed.\n"
  printf "[c] 2020 WeakNet Labs. \n\n"
  # open the site:
  firefox 'http://127.0.0.1/owasp-lab/'
fi
