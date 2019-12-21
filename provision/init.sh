sudo apt-get -y update
sudo apt-get -y git install nginx nodejs npm
git clone https://github.com/schrist2/ba-demo-app.git code
cd code
sudo npm install
sudo node bin/www
sudo cp nginx.conf /etc/nginx/sites-enabled/default
sudo service nginx restart