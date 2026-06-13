server {
    listen {{ .interface }}:{{ .port }} default_server;

    include /etc/nginx/includes/server_params.conf;
    include /etc/nginx/includes/proxy_params.conf;
    location / {
        allow   172.30.32.2;
        allow   127.0.0.1;
        deny    all;
        proxy_pass http://127.0.0.1:8888;

        # Rewrite absolute paths in responses
        sub_filter_once off;
        sub_filter_types *;
        sub_filter 'href="/' 'href="{{ .ingress_entry }}/';
        sub_filter 'src="/' 'src="{{ .ingress_entry }}/';
        sub_filter 'url(/' 'url({{ .ingress_entry }}/';
        sub_filter "'url':'/" "'url':'{{ .ingress_entry }}/";
    }
}