module vxbl-oauth

import vweb
import xbl
import json
import os

const (
	port = 80
)

struct App {
	vweb.Context
mut:
	cnt   int
	// pub:
	login xbl.LoginData
}

// loads the config if exists; saves the config and stops the server for setup if not
fn (mut app App) load_config() {
	app.login = xbl.LoginData{}
	fpath := './login.conf'
	if !os.is_file(fpath) {
		arr := [
			'client_id=$app.login.client_id',
			'client_secret=$app.login.client_secret',
			'redirect_uri=$app.login.redirect_uri',
			'locale=$app.login.locale',
		]
		os.write_file(fpath, arr.join_lines())
		panic('Configuration was not set up')
	}
	read := os.read_file(fpath) or { panic(err) }
	rarr := read.split_into_lines()
	assert rarr.len == 4
	println(rarr)
	mut m := map[string]string{}
	for ln in rarr {
		m[ln.all_before('=')] = ln.all_after('=')
	}
	assert m.len == 4
	assert 'client_id' in m
	assert 'client_secret' in m
	assert 'redirect_uri' in m
	assert 'locale' in m
	app.login = xbl.LoginData{
		client_id: m['client_id']
		client_secret: m['client_secret']
		redirect_uri: m['redirect_uri']
		locale: m['locale']
	}
}

fn main() {
	mut app := App{}
	app.load_config()
	vweb.run_app<App>(mut app, port)
}

pub fn (mut app App) index() vweb.Result {
	request_url := app.login.get_request_url()
	app.redirect(request_url)
	return $vweb.html()
}

pub fn (mut app App) signin() vweb.Result {
	code := app.query['code']
	access_token_info := app.login.get_access_token_info(code)
	authentication_info := xbl.get_authentication_info(access_token_info['access_token'])
	authorization_info := xbl.get_authorization_info(authentication_info['Token'])
	$if debug {
		println(json.encode(authorization_info))
	}
	// mut xuid := authorization_info.display_claims["xui"][0].xuid
	gamertag := authorization_info.display_claims['xui'][0].gamertag // TODO figure out a way to make warning shut up
	return $vweb.html()
}
