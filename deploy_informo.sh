#!/bin/bash

###################
### Config  	###
###################

# Domain Name of the server
serverName='91.121.82.24'

# Open port
openPort=8008

# Mail for let'sencrypt registration, 'off' means no ssl
#tlsMail='matrix-node@dontcare.com'
tlsMail='off'

# Directory for matrix server data
dataDir='/matrix/server/data'

# Directory for caddy server (to save certs)
caddyDir='/matrix/caddy'



###################
### Process  	###
###################

# Some defines
internalPort=3478

# Launch a tmp docker container to generate Matrix. This will create a own self-signed certificate.
docker run -v $dataDir:/data --rm -e SERVER_NAME=$serverName -e REPORT_STATS=no silviof/docker-matrix generate

# Launch a docker container as daemon to host Matrix server (Synapse).
#docker run -d -p 8448:8448 -p 127.0.0.1:$internalPort:$internalPort -v $dataDir:/data --name='matrix-server' silviof/docker-matrix start
docker run -d -p 8448:8448 -v $dataDir:/data --name='matrix-server' silviof/docker-matrix start

# Write Caddyfile
cp $(pwd)/template_Caddyfile $(pwd)/generated_Caddyfile
sed -i -e "s/<%serverName%>/$serverName/g" $(pwd)/generated_Caddyfile
sed -i -e "s/<%internalPort%>/$internalPort/g" $(pwd)/generated_Caddyfile
sed -i -e "s/<%tlsMail%>/$tlsMail/g" $(pwd)/generated_Caddyfile

# Launch caddy server as reverse proxy
docker run -d -p $openPort:80 -v $(pwd)/generated_Caddyfile:/etc/Caddyfile -v $caddyDir:/root/.caddy --name='caddy-server' zzrot/alpine-caddy

