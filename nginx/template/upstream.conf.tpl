upstream myapp {
	server {{ACTIVE_COLOR}}:8080;
}

server {
	listen 80;

	location / {
		proxy_pass http://myapp;
	}
}
