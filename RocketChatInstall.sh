# Youtube: https://youtu.be/1Eowk4PI2Rg

sudo apt-get update
sudo apt-get upgrade

# Install the official MongoDB
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 9DA31620334BD75D9DCB49F368818C72E52529D4
echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.0.list

# Configure Node.js to be installed via package manager
sudo apt-get -y update && sudo apt-get install -y curl && curl -sL https://deb.nodesource.com/setup_8.x | sudo bash -

# Install build tools, MongoDB, nodejs and graphicsmagick:
sudo apt-get install -y build-essential mongodb-org nodejs graphicsmagick

# Download the latest Rocket.Chat version:
curl -L https://releases.rocket.chat/latest/download -o /tmp/rocket.chat.tgz
tar -xzf /tmp/rocket.chat.tgz -C /tmp

# Install Rocket Chat
cd /tmp/bundle/programs/server && npm install
sudo mv /tmp/bundle /opt/Rocket.Chat

# Configure the Rocket.Chat service
# Add the rocketchat user, set the right permissions
sudo useradd -M rocketchat && sudo usermod -L rocketchat
sudo chown -R rocketchat:rocketchat /opt/Rocket.Chat

cat << EOF |sudo tee -a /lib/systemd/system/rocketchat.service
[Unit]
Description=The Rocket.Chat server
After=network.target remote-fs.target nss-lookup.target nginx.target mongod.target
[Service]
ExecStart=/usr/bin/node /opt/Rocket.Chat/main.js
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=rocketchat
User=rocketchat
Environment=MONGO_URL=mongodb://localhost:27017/rocketchat?replicaSet=rs01 MONGO_OPLOG_URL=mongodb://localhost:27017/local?replicaSet=rs01 ROOT_URL=http://localhost:3000/ PORT=3000
[Install]
WantedBy=multi-user.target
EOF


# Open the Rocket.Chat service file just created (/lib/systemd/system/rocketchat.service) using sudo and your favourite text editor, and change the ROOT_URL environmental variable to reflect the URL you want to use for accessing the server (optionally change MONGO_URL, MONGO_OPLOG_URL and PORT):

sudo nano /lib/systemd/system/rocketchat.service

#MONGO_URL=mongodb://localhost:27017/rocketchat?replicaSet=rs01
#MONGO_OPLOG_URL=mongodb://localhost:27017/local?replicaSet=rs01
#ROOT_URL=http://your-host-name.com-as-accessed-from-internet:3000
#PORT=3000


# Setup storage engine and replication for MongoDB, and enable and start MongoDB and Rocket.Chat:

sudo sed -i "s/^#  engine:/  engine: mmapv1/"  /etc/mongod.conf
sudo sed -i "s/^#replication:/replication:\n  replSetName: rs01/" /etc/mongod.conf
sudo systemctl enable mongod && sudo systemctl start mongod
mongo --eval "printjson(rs.initiate())"
sudo systemctl enable rocketchat && sudo systemctl start rocketchat

# Install Nginx
sudo apt-get install nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# remove default nxgix page
sudo rm /etc/nginx/sites-enabled/default

# Create a new configuration for Rocket Chat
sudo nano /etc/nginx/sites-available/yourdomainname.conf

# Copy paste bellow content and save
# upstream backend {
#    server 127.0.0.1:3000;
#} 

#server {
#    listen [::]:80;
#    listen 80;
#    server_name yourdomainname.com;
#   client_max_body_size 200M;
#   error_log /var/log/nginx/rocketchat.access.log;

#   location / {
#        proxy_pass http://backend/;
#        proxy_http_version 1.1;
#        proxy_set_header Upgrade $http_upgrade;
#        proxy_set_header Connection "upgrade";
#        proxy_set_header Host $http_host;
         
#         proxy_set_header X-Real-IP $remote_addr;
#         proxy_set_header X-Forward-For $proxy_add_x_forwarded_for;
#         proxy_set_header X-Forward-Proto http;
#         proxy_set_header X-Nginx-Proxy true;

#         proxy_redirect off;
#    } 
#}



# Configure your Rocket.Chat server
# Open a web browser and access the configured ROOT_URL 
# http://your-host-name.com:3000
