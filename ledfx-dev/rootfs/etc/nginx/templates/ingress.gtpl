server {
    listen {{ .interface }}:{{ .port }} default_server;

    include /etc/nginx/includes/server_params.conf;
    include /etc/nginx/includes/proxy_params.conf;
    location {{ .ingress_entry }}/ {

        proxy_pass http://backend/;

        # Rewrite absolute paths in responses
        sub_filter_once off;
        sub_filter_types *;
        sub_filter 'href="/' 'href="{{ .ingress_entry }}/';
        sub_filter 'src="/' 'src="{{ .ingress_entry }}/';
        sub_filter 'url(/' 'url({{ .ingress_entry }}/';
    }
    location / {
        allow   172.30.32.2;
        deny    all;

        return 301 {{ .ingress_entry }}/;
    }
}
