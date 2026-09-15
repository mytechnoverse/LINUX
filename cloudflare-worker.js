
const ORIGIN = "https://deb.debian.org/debian";

export default {
    async fetch( request ) {
        if ( request.method === "GET" ) {
            const request_url = new URL( request.url );

            const target_url = new URL( request_url.pathname + request_url.search , ORIGIN );
            const request_headers = new Headers( request.headers );
            request_headers.delete("Host");
            const upstream = new Request( target_url , {
                method: "GET" ,
                request_headers ,
            });
            const response = await fetch( upstream , {
                cache: "no-store" ,
            });
            const output = new Response( response.body , response );
            return output ;
        }
    } ,
};





const router_dictionary = {}
router_dictionary['debian'] = 'https://deb.debian.org/debian/' 
router_dictionary['debian-security'] = 'https://security.debian.org/debian-security/'
router_dictionary['ubuntu'] = 'https://archive.ubuntu.com/ubuntu/'
router_dictionary['ubuntu-security'] = 'https://security.ubuntu.com/ubuntu/'
router_dictionary['npmjs'] = 'https://registry.npmjs.org/'
router_dictionary['docker'] = 'https://registry-1.docker.io'
router_dictionary['docker-auth'] = 'https://auth.docker.io/'

if ( url.pathname.startsWith('/v2/token') ) -> auth









Www-Authenticate challenge headers




export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    
    const REGISTRY_HOST = 'registry-1.docker.io';
    const AUTH_HOST = 'auth.docker.io';

    // Route requests to auth server if it's a token request, otherwise to the registry
    let targetHost = REGISTRY_HOST;
    if (url.pathname.startsWith('/v2/token') || url.pathname.startsWith('/token')) {
      targetHost = AUTH_HOST;
      // Adjust path if necessary depending on how docker hits it
      if (url.pathname.startsWith('/v2/token')) {
        url.pathname = url.pathname.replace('/v2/token', '/token');
      }
    }

    url.host = targetHost;

    // Create the proxied request
    const modifiedRequest = new Request(url.toString(), {
      method: request.method,
      headers: request.headers,
      body: request.body,
      redirect: 'manual' // Crucial: lets Docker client follow S3 layer redirects directly
    });

    let response;
    try {
      response = await fetch(modifiedRequest);
    } catch (e) {
      return new Response(`Proxy error: ${e.message}`, { status: 500 });
    }

    // Handle 401 Unauthorized responses to fix the authentication realm URL
    if (response.status === 401) {
      const newHeaders = new Headers(response.headers);
      const wwwAuth = newHeaders.get('Www-Authenticate');
      
      if (wwwAuth) {
        const workerOrigin = new URL(request.url).origin;
        // Rewrite the auth realm to point to your worker instead of auth.docker.io
        const updatedAuth = wwwAuth.replace(/realm="https:\/\/[^"]+/, `realm="${workerOrigin}/v2/token`);
        newHeaders.set('Www-Authenticate', updatedAuth);
      }

      return new Response(response.body, {
        status: response.status,
        statusText: response.statusText,
        headers: newHeaders
      });
    }

    return response;
  }
};


request_url_path_prefix
