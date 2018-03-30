/**
 * @package Detox DHT
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
bencode			= require('bencode')
webrtc-socket	= require('webtorrent-dht/webrtc-socket')
webtorrent-dht	= require('webtorrent-dht')

module.exports	=
	'bencode'			: bencode
	'webrtc-socket'		: webrtc-socket
	'webtorrent-dht'	: webtorrent-dht
