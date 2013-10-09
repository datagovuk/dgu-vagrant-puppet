# Common for all DGU machines

acl ClearCache {
    "localhost";
    "127.0.0.1";
    "co-prod1.dh.bytemark.co.uk";
    "co-prod2.dh.bytemark.co.uk";
    "co-prod3.dh.bytemark.co.uk";
    "co-staging1.dh.bytemark.co.uk";
    "co-staging2.dh.bytemark.co.uk";
}


sub vcl_error {
    # If we get our magic, invented http code, redirect the response (+url) to
    # data.gov.uk instead.
    if (obj.status == 750) {
        set obj.http.Location = "http://co-prod3.dh.bytemark.co.uk" + req.url;
        set obj.status = 301;
        return (deliver);
    }
}

sub vcl_recv {

   # Sanitize the host header to remove port numbers
   set req.http.Host = regsub(req.http.Host, ":[0-9]+", "");

   # Redirect requests to www. to just the hostname part
   # www.data.gov.uk will eventually 301 to data.gov.uk (see vcl_error)
   if ( req.http.host ~ "^www.co-prod3.dh.bytemark.co.uk" &&
            req.http.X-Forwarded-Proto !~ "(?i)https") {
        error 750 "Moved Permanently";
    }

  set req.http.X-Forwarded-For = client.ip;
  set req.grace = 3m;

  if ( req.http.user-agent == "gsa-crawler (Enterprise; T3-MZAPJG37KYWBJ; nobody@google.com,christopher.king@newsint.co.uk)" ) {
      # 143.252.80.100 newsint - regularly 19 req/s from GSA April 2013
      error 403 "Requests from your agent are blocked. Contact system administrator david.read@hackneyworkshop.com for further information.";
  }

  # Send particular URLs to CKAN (only runs on one backend at a time)
  # NB the regex must correspond with the WSGIScriptAlias URLs listed in the apache config

  # We can merge these and let nginx proxy as necessary
  if (req.url ~ "^/data-requests/") {
    set req.backend = drupalbackend;
    set req.http.X-App = "drupal";
  } else  if (req.url ~ "^/(data|dataset|font|publisher|unpublished|inventory|css|images|scripts|api|geoserver|harvest|ckanext|ckan-admin|qa|revision|feeds|img|csw|assets)") {
      set req.backend = ckanbackend;
      set req.http.X-App = "ckan";
  }
  else {
    set req.backend = drupalbackend;
    set req.http.X-App = "drupal";
  }


  ## Pass cron jobs
  if (req.url ~ "cron.php") {
    return (pass);
  }

  # Don't cache install.php
  if (req.url ~ "install.php") {
    return (pass);
  }


  if (req.http.Accept-Encoding) {
    if (req.url ~ "\.(jpg|png|gif|gz|tgz|bz2|tbz|mp3|ogg)$") {
      # No point in compressing these
      remove req.http.Accept-Encoding;
    }
    elsif (req.http.Accept-Encoding ~ "gzip") {
      set req.http.Accept-Encoding = "gzip";
    }
    else {
      # unkown or deflate algorithm - remove
      remove req.http.Accept-Encoding;
    }
  }

  if (req.url ~ "^/sites") {
    unset req.http.cookie;
  }

  # Don't cache Drupal logged-in user sessions
  # LOGGED_IN is the cookie that earlier version of Pressflow sets
  # VARNISH is the cookie which the varnish.module sets
  if (req.http.Cookie ~ "(VARNISH|DRUPAL_UID|LOGGED_IN)") {
    return (pass);
  }

  // Remove has_js and Google Analytics cookies. Evan added sharethis cookies
  set req.http.Cookie = regsuball(req.http.Cookie, "(^|;\s*)(__[a-z]+|has_js|cookie-agreed-en|_csoot|_csuid|_chartbeat2)=[^;]*", "");

  // Remove a ";" prefix, if present.
  set req.http.Cookie = regsub(req.http.Cookie, "^;\s*", "");
  // Remove empty cookies.
  if (req.http.Cookie ~ "^\s*$") {
    unset req.http.Cookie;
  }

  if (req.request == "BAN") {
    # To clear some or all of the cache
    # e.g. curl -X BAN http://data.gov.uk/css/dgu.css
    #      curl -X BAN http://data.gov.uk/  (to clear all of the site)
    if (!client.ip ~ ClearCache) {
        error 405 "Not allowed.";
    }

    #purge("req.url ~ " req.url);

    #error 200 "Cached Cleared Successfully.";
    return (lookup);
  }

  # Cache things with these extensions
  if (req.url ~ "\.(js|css|jpg|jpeg|png|gif|gz|tgz|bz2|tbz|mp3|ogg|swf)$") {
    return (lookup);
  }
}


sub vcl_fetch {

  if ( beresp.status >= 500 ) {
    set beresp.ttl = 0s;
  }

  if (req.url ~ "^/sites") {
    unset beresp.http.set-cookie;
  }

  # CKAN cache headers are used by Varnish cache, but should not be propagated to
  # the Internet. Tell browsers and proxies not to cache. This means Varnish always
  # gets the responsibility to server the right content at all times.
  if (req.http.X-App == "ckan" && beresp.http.Cache-Control ~ "max-age") {
    unset beresp.http.set-cookie;
    set beresp.http.Cache-Control = "no-cache";
  }

  # Encourage assets to be cached by proxies and browsers
  # JS and CSS may be gzipped depending on headers
  # see https://developers.google.com/speed/docs/best-practices/caching
  if (req.url ~ "\.(css|js)") {
    set beresp.http.Vary = "Accept-Encoding";
  }

  # Encourage assets to be cached by proxies and browsers for 1 day
  if (req.url ~ "\.(png|gif|jpg|swf|css|js)") {
    unset beresp.http.set-cookie;
    set beresp.http.Cache-Control = "public, max-age=86400";
    set beresp.ttl = 1d;
  }

  # Encourage CKAN vendor assets (which are versioned) to be cached by
  # by proxies and browsers for 1 year
  if (req.url ~ "^/scripts/vendor/") {
    unset beresp.http.set-cookie;
    set beresp.http.Cache-Control = "public, max-age=31536000";
    set beresp.ttl = 12m;
  }

  // Apache sometimes returns empty documents with 200 OK status. These are then gzipped to 20 bytes.
  // Can come from "mysql gone away errors", Don't cache these small blank pages
  if (beresp.http.Content-Length == "20") {
    if ( (beresp.http.Content-Encoding == "gzip") && (beresp.status == 200) ) {
      error 500;
    }
  }

  set req.grace = 2m;
}


sub vcl_hash {
  if (req.http.Cookie) {
    hash_data(req.http.Cookie);
    #set req.hash += req.http.Cookie;
  }
}


sub vcl_deliver {
  if (resp.http.x-reset-age) {
    unset resp.http.x-reset-age;
    set resp.http.age = "0";
  }

  set resp.http.X-App = req.http.X-App;

  if (obj.hits > 0) {
    set resp.http.X-Varnish-Cache = "HIT";
  }
  else {
    set resp.http.X-Varnish-Cache = "MISS";
  }

}

