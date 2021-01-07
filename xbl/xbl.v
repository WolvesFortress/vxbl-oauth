module xbl

import net.http
import json

pub struct LoginData {
pub:
	client_id     string
	client_secret string
	redirect_uri  string
	locale        string = 'en-US'
}

pub fn (mut d LoginData) get_request_url() string {
	mut data := {
		'client_id':     d.client_id
		'scope':         'XboxLive.signin'
		'response_type': 'code'
		'redirect_uri':  d.redirect_uri
		'locale':        'en-US'
	}
	return 'https://login.live.com/oauth20_authorize.srf?' + http.url_encode_form_data(data)
}

fn parse_json_response(response http.Response) map[string]string {
	mut data := json.decode(map[string]string, response.text) or {
		error('Failed to decode Response.') // AuthorizationInfoResponse cannot be decoded this way
		return map[string]string{}
	}
	if 'error' in data {
		error(data['error'] + ': ' + data['error_description'])
	}
	return data
}

// Client is redirected to request_uri?code=code after they log in via getRequestUrl().
pub fn (d LoginData) get_access_token_info(code string) map[string]string {
	url := 'https://login.microsoftonline.com/consumers/oauth2/v2.0/token'
	fields := {
		'grant_type':    'authorization_code'
		'code':          code
		'client_id':     d.client_id
		'scope':         'XboxLive.signin'
		'redirect_uri':  d.redirect_uri
		'client_secret': d.client_secret
	}
	resp := http.post_form(url, fields) or {
		error('Requesting signin data from oauth2 failed')
		panic(err)
	}
	return parse_json_response(resp)
}

struct AuthenticateData {
	relying_party string                     [json: RelyingParty]
	token_type    string                     [json: TokenType]
	properties    AuthenticateDataProperties [json: Properties]
}

struct AuthenticateDataProperties {
	auth_method string [json: AuthMethod]
	site_name   string [json: SiteName]
	rps_ticket  string [json: RpsTicket]
}

// Access token can be retrieved from getAccessTokenInfo() (key = "access_token").
pub fn get_authentication_info(access_token string) map[string]string {
	url := 'https://user.auth.xboxlive.com/user/authenticate'
	fields := AuthenticateData{
		relying_party: 'http://auth.xboxlive.com'
		token_type: 'JWT'
		properties: AuthenticateDataProperties{
			auth_method: 'RPS'
			site_name: 'user.auth.xboxlive.com'
			rps_ticket: 'd={$access_token}'
		}
	}
	resp := http.post_json(url, json.encode(fields)) or {
		error('Posting AuthenticateData json failed')
		panic(err)
	}
	return parse_json_response(resp)
}

struct AuthorizationInfo {
	relying_party string                      [json: RelyingParty]
	token_type    string                      [json: TokenType]
	properties    AuthorizationInfoProperties [json: Properties]
}

struct AuthorizationInfoProperties {
	user_tokens []string [json: UserTokens]
	sandbox_id  string   [json: SandboxId]
}

struct AuthorizationInfoResponse {
pub:
	issue_instant  string                                                 [json: IssueInstant]
	not_after      string                                                 [json: NotAfter]
	token          string                                                 [json: Token]
	display_claims map[string][]AuthorizationInfoResponseDisplayClaimsXui [json: DisplayClaims]
}

struct AuthorizationInfoResponseDisplayClaimsXui {
pub:
	gamertag string [json: gtg]
	xuid     string [json: xid]
	uhs      string [json: uhs]
	agg      string [json: agg]
	usr      string [json: usr]
	utr      string [json: utr]
	prv      string [json: prv]
}

// User token can be retrieved from getAuthenticationInfo() (key = "Token").
pub fn get_authorization_info(user_token string) AuthorizationInfoResponse {
	url := 'https://xsts.auth.xboxlive.com/xsts/authorize'
	fields := AuthorizationInfo{
		relying_party: 'http://xboxlive.com'
		token_type: 'JWT'
		properties: AuthorizationInfoProperties{
			user_tokens: [user_token]
			sandbox_id: 'RETAIL'
		}
	}
	resp := http.post_json(url, json.encode(fields)) or {
		error('Posting AuthorizationInfo json failed')
		panic(err)
	}
	res := json.decode(AuthorizationInfoResponse, resp.text) or {
		error('Decoding AuthorizationInfo json failed')
		panic(err)
	}
	return res
}
