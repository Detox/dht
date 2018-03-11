/**
 * @package Detox DHT
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
bencode			= require('bencode')
simple-peer		= require('simple-peer')
webrtc-socket	= require('webtorrent-dht/webrtc-socket')
webtorrent-dht	= require('webtorrent-dht')

module.exports	=
	'bencode'			: bencode
	'simple-peer'		: simple-peer
	'webrtc-socket'		: webrtc-socket
	'webtorrent-dht'	: webtorrent-dht
