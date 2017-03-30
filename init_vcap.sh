sudo adduser --disabled-password --gecos "" vcap
echo vcap:vcap | sudo chpasswd
sudo grep -q  vcap /etc/sudoers;if [[ "$?" != "0" ]];then 
  echo "vcap ALL=(ALL) NOPASSWD:ALL"|sudo tee -a /etc/sudoers
fi
sudo su vcap -c "source /home/df/bin/setproxy.sh; \
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3; \
\curl -sSL https://get.rvm.io | bash -s stable; \
source /home/vcap/.rvm/scripts/rvm
rvm install 2.1.5; \
rvm use 2.1.5
gem install bundler
"
