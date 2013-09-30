#
# Default Varnish configuration to be included on all environments
#

backend drupalbackend {
      .host = "127.0.0.1";
      .port = "8009";
      .connect_timeout = 5s;
      .first_byte_timeout = 60s;
      .between_bytes_timeout = 10s;
      .probe = {
        .url = "/__utm.gif";
        .interval = 30s;
        .timeout = 3s;
        .window = 5;
        .threshold = 3;
      }
}
backend ckanbackend {
      .host = "127.0.0.1";
      .port = "8000";
      .connect_timeout = 5s;
      .first_byte_timeout = 60s;
      .between_bytes_timeout = 10s;
      .probe = {
        .url = "/api/util/status";
        .interval = 30s;
        .timeout = 3s;
        .window = 5;
        .threshold = 3;
      }
}

include "/etc/varnish/common.vcl";
