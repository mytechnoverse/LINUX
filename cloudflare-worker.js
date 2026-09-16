
// expose https proxy

const router_dictionary = {
	'dns-query': 'https://cloudflare-dns.com/dns-query' ,
	'npmjs': 'https://registry.npmjs.org' ,
	'ubuntu': 'https://archive.ubuntu.com/ubuntu' ,
	'ubuntu-security': 'https://security.ubuntu.com/ubuntu' ,
	'ubuntu-nginx': 'https://nginx.org/packages/ubuntu' ,
	'debian': 'https://deb.debian.org/debian' ,
	'debian-security': 'https://security.debian.org/debian-security' ,
	'debian-nginx': 'https://nginx.org/packages/debian' ,
	'docker-auth': 'https://auth.docker.io' ,
	'v2': 'https://registry-1.docker.io' ,
} ;

export default {
	async fetch( request ) {

		const redirect_header_name = 'Location' ;
		const docker_auth_header_name = 'WWW-Authenticate' ;
		const general_auth_header_names_list = [ 'authorization' , 'cookie' ];
		const client_request_method = request.method ;
		const client_request_headers = new Headers( request.headers );
		client_request_headers.delete( 'Host' );
		const client_request_url = new URL( request.url ) ;
		const client_request_url_path = client_request_url.pathname ;
		const client_request_url_query = client_request_url.search ;
		const cloudflare_worker_url = client_request_url.origin ;
		

		for ( const route_name of Object.keys( router_dictionary ) ) {
			const this_route_url_path_prefix = '/' + route_name ;
			if ( client_request_url_path.startsWith( this_route_url_path_prefix ) == false ) {
				continue
			}
			let target_request_url_path = client_request_url_path ;
			if ( route_name != 'v2' ) {
				target_request_url_path = target_request_url_path.slice( this_route_url_path_prefix.length ) ;
			}
			const target_url = new URL( target_request_url_path + client_request_url_query , router_dictionary[ route_name ] );
			target_request = new Request( target_url , {
				method: client_request_method ,
				headers: client_request_headers ,
				body: ( client_request_method == 'GET' || client_request_method == 'HEAD' ) ? undefined : request.body ,
				redirect: ( route_name == 'v2' ) ? 'manual' : 'follow' ,
			});
			let target_response = await fetch( target_request , {
				cache: 'no-store' ,
			});
			if ( route_name != 'v2' ) {
				return target_response ;
			} else {
				if ( target_response.status == 307 ) {
					const new_target_headers = new Headers( target_response.headers );
					const target_response_redirect_url = new_target_headers.get( redirect_header_name ) ;
					const new_target_url = new URL( target_response_redirect_url , target_url );

				}
				if ( target_response.status == 401 ) {
					if ( target_response.headers.has( docker_auth_header_name ) ) {
						let target_response_headers_auth_proxied = new Headers( target_response.headers );
						let target_response_docker_auth_header = target_response_headers_auth_proxied.get( docker_auth_header_name );
						if ( target_response_docker_auth_header.startsWith( 'Bearer' ) ) {
							const docker_auth_realm_official_key_value = 'realm="' + router_dictionary[ 'docker-auth' ] + '/token"' ;
							const docker_auth_realm_proxied_key_value = 'realm="' + cloudflare_worker_url + '/docker-auth/token"' ;
							const target_response_docker_auth_header_proxied = target_response_docker_auth_header.replace(
								docker_auth_realm_official_key_value ,
								docker_auth_realm_proxied_key_value
							);
							target_response_headers_auth_proxied.set( docker_auth_header_name , target_response_docker_auth_header_proxied );
							target_response = new Response(
								target_response.body , {
									status: target_response.status ,
									statusText: target_response.statusText ,
									headers: target_response_headers_auth_proxied ,
								}
							);
							return target_response ;
						}
					}
				}
			}
		}
	}
};





for ( const general_auth_header_name of general_auth_header_names_list ) {
	if ( redirect_headers.has( http_auth_header_name ) ) {
		redirect_headers.delete( http_auth_header_name );
	}
}





while (  && redirect_hops < 5 ) {
	let this_redirect_url ;
	



    target_response = await fetch( redirect_target_url , {
        method: ( client_request_method == 'HEAD' ) ? 'HEAD' : 'GET' ,
        headers: redirect_headers ,
        cache: 'no-store' ,
    });
    redirect_hops++ ;
}









