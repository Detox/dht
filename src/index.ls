/**
 * @package Detox DHT
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
function Wrapper (detox-crypto, async-eventer, es-dht)
	/**
	 * @constructor
	 *
	 * @param {!Uint8Array}		dht_public_key						Own ID
	 * @param {!Array<!Object>}	bootstrap_nodes						Array of objects with keys (all of them are required) `node_id`, `host` and `ip`
	 * @param {!Function}		hash_function						Hash function to be used for Merkle Tree
	 * @param {!Function}		verify								Function for verifying Ed25519 signatures, arguments are `Uint8Array`s `(signature, data. public_key)`
	 * @param {number}			bucket_size							Size of a bucket from Kademlia design
	 * @param {number}			state_history_size					How many versions of local history will be kept
	 * @param {number}			fraction_of_nodes_from_same_peer	Max fraction of nodes originated from single peer allowed on lookup start
	 *
	 * @return {!DHT}
	 */
#	!function DHT (dht_public_key, bootstrap_nodes)
	!function DHT (dht_public_key, bootstrap_nodes, hash_function, verify, bucket_size, state_history_size, fraction_of_nodes_from_same_peer = 0.2)
		if !(@ instanceof DHT)
			return new DHT(dht_public_key, bootstrap_nodes, hash_function, verify, bucket_size, state_history_size, fraction_of_nodes_from_same_peer)
		async-eventer.call(@)

	DHT:: =
		/**
		 * @param {!Uint8Array}	seed			Seed used to generate bootstrap node's keys (it may be different from `dht_public_key` in constructor for scalability purposes
		 * @param {string}		ip				IP on which to listen
		 * @param {number}		port			Port on which to listen
		 * @param {string=}		public_address	Publicly reachable address (can be IP or domain name) reachable
		 * @param {number=}		public_port		Port that corresponds to `public_address`
		 */
		'listen' : (seed, ip, port, public_address = ip, public_port = port) ->
			keypair	= detox-crypto['create_keypair'](seed)
			# TODO
		/**
		 * @param {!Uint8Array} id
		 *
		 * @return {!Promise}
		 */
		'lookup' : (id) ->
		/**
		 * @return {!Array<!Uint8Array>}
		 */
		'get_peers' : ->
		/**
		 * @param {!Uint8Array} key
		 *
		 * @return {!Promise}
		 */
		'get' : (key) ->
		/**
		 * @param {!Uint8Array} data
		 *
		 * @return {!Uint8Array} Key
		 */
		'put_immutable' : (data) ->
		/**
		 * @param {!Uint8Array} public_key
		 * @param {!Uint8Array} data
		 * @param {!Uint8Array} signature
		 */
		'put_mutable' : (public_key, data, signature) !->
		'destroy' : ->

	DHT:: = Object.assign(Object.create(async-eventer::), DHT::)
	Object.defineProperty(DHT::, 'constructor', {value: DHT})

	{
		'ready'	: detox-crypto['ready']
		'DHT'	: DHT
	}

if typeof define == 'function' && define['amd']
	# AMD
	define(['@detox/crypto', 'async-eventer', 'es-dht'], Wrapper)
else if typeof exports == 'object'
	# CommonJS
	module.exports = Wrapper(require('@detox/crypto'), require('async-eventer'), require('es-dht'))
else
	# Browser globals
	@'detox_dht' = Wrapper(@'detox_crypto', 'async_eventer', @'es_dht')
