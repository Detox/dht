/**
 * @package Detox DHT
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
function Wrapper (async-eventer, es-dht)
	/**
	 * @constructor
	 *
	 * @param {!Uint8Array}	id									Own ID
	 * @param {!Function}	hash_function						Hash function to be used for Merkle Tree
	 * @param {number}		bucket_size							Size of a bucket from Kademlia design
	 * @param {number}		state_history_size					How many versions of local history will be kept
	 * @param {number}		fraction_of_nodes_from_same_peer	Max fraction of nodes originated from single peer allowed on lookup start
	 *
	 * @return {!DHT}
	 */
	!function DHT (id, hash_function, bucket_size, state_history_size, fraction_of_nodes_from_same_peer = 0.2)
		if !(@ instanceof DHT)
			return new DHT(id, hash_function, bucket_size, state_history_size, fraction_of_nodes_from_same_peer)
		async-eventer.call(@)

	DHT:: =
		/**
		 * @param {string}	ip
		 * @param {number}	port
		 */
		'listen' : (ip, port) ->
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

	DHT

if typeof define == 'function' && define['amd']
	# AMD
	define(['async-eventer', 'es-dht'], Wrapper)
else if typeof exports == 'object'
	# CommonJS
	module.exports = Wrapper(require('async-eventer'), require('es-dht'))
else
	# Browser globals
	@'detox_dht' = Wrapper(@'async_eventer', @'es_dht')
