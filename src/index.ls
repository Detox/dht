/**
 * @package Detox DHT
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
const ID_LENGTH			= 32
const SIGNATURE_LENGTH	= 64
const COMMAND_RESPONSE	= 0
const COMMAND_GET_STATE	= 1
const COMMAND_GET_PROOF	= 2
const COMMAND_GET_VALUE	= 3
const COMMAND_PUT_VALUE	= 4
# In seconds
const DEFAULT_TIMEOUTS	=
	'GET_PROOF_REQUEST_TIMEOUT'	: 5
	'GET_STATE_REQUEST_TIMEOUT'	: 10
	'GET_VALUE_TIMEOUT'			: 5
	'PUT_VALUE_TIMEOUT'			: 5
	# TODO: This number will likely need to be tweaked
	'STATE_UPDATE_INTERVAL'		: 15
# Allow up to 1 KiB of data to be stored as mutable or immutable value in DHT
const MAX_VALUE_LENGTH	= 1024
/**
 * @param {!Uint8Array} state_version
 * @param {!Uint8Array} node_id
 *
 * @return {!Uint8Array}
 */
function compose_get_proof_request (state_version, node_id)
	new Uint8Array(ID_LENGTH * 2)
		..set(node_id, ID_LENGTH)
		..set(state_version)
/**
 * @param {!Uint8Array} data
 *
 * @return {!Array<!Uint8Array>} `[state_version, node_id]`
 */
function parse_get_proof_request (data)
	state_version	= data.subarray(0, ID_LENGTH)
	node_id			= data.subarray(ID_LENGTH)
	[state_version, node_id]
/**
 * @param {number}		transaction_id
 * @param {!Uint8Array}	data
 *
 * @return {!Uint8Array}
 */
function compose_payload (transaction_id, data)
	array	= new Uint8Array(2 + data.length)
		..set(data, 2)
	new DataView(array.buffer)
		..setUint16(0, transaction_id, false)
	array
/**
 * @param {!Uint8Array} payload
 *
 * @return {!Array} `[transaction_id, data]`
 */
function parse_payload (payload)
	view			= new DataView(payload.buffer, payload.byteOffset, payload.byteLength)
	transaction_id	= view.getUint16(0, false)
	data			= payload.subarray(2)
	[transaction_id, data]
/**
 * @param {number}		version
 * @param {!Uint8Array}	value
 *
 * @return {!Uint8Array}
 */
function compose_mutable_value (version, value)
	array	= new Uint8Array(4 + value.length)
		..set(value, 4)
	new DataView(array.buffer)
		..setUint32(0, version, false)
	array
/**
 * @param {!Uint8Array} payload
 *
 * @return {!Array} `[version, value]`
 */
function parse_mutable_value (payload)
	view	= new DataView(payload.buffer, payload.byteOffset, payload.byteLength)
	version	= view.getUint32(0, false)
	value	= payload.subarray(4)
	[version, value]
/**
 * @param {!Uint8Array} key
 * @param {!Uint8Array} payload
 *
 * @return {!Uint8Array}
 */
function compose_put_value_request (key, payload)
	new Uint8Array(ID_LENGTH + payload.length)
		..set(key)
		..set(payload, ID_LENGTH)
/**
 * @param {!Uint8Array} data
 *
 * @return {!Array<!Uint8Array>} `[key, payload]`
 */
function parse_put_value_request (data)
	key		= data.subarray(0, ID_LENGTH)
	payload	= data.subarray(ID_LENGTH)
	[key, payload]

function Wrapper (detox-crypto, detox-utils, async-eventer, es-dht)
	blake2b_256			= detox-crypto['blake2b_256']
	create_signature	= detox-crypto['sign']
	verify_signature	= detox-crypto['verify']
	are_arrays_equal	= detox-utils['are_arrays_equal']
	concat_arrays		= detox-utils['concat_arrays']
	timeoutSet			= detox-utils['timeoutSet']
	intervalSet			= detox-utils['intervalSet']
	ArrayMap			= detox-utils['ArrayMap']
	error_handler		= detox-utils['error_handler']
	null_array			= new Uint8Array(0)

	/**
	 * @param {!Uint8Array}			state_version
	 * @param {!Uint8Array}			proof
	 * @param {!Array<!Uint8Array>}	peers
	 *
	 * @return {!Uint8Array}
	 */
	function compose_state (state_version, proof, peers)
		proof_height	= proof.length / (ID_LENGTH + 1)
		peers			= concat_arrays(peers)
		new Uint8Array(ID_LENGTH + 1 + proof.length + peers.length)
			..set(state_version)
			..set([proof_height], ID_LENGTH)
			..set(proof, ID_LENGTH + 1)
			..set(peers, ID_LENGTH + 1 + proof.length)
	/**
	 * @param {!Uint8Array} data
	 *
	 * @return {!Array} `[state_version, proof, peers]`
	 */
	function parse_state (data)
		state_version	= data.subarray(0, ID_LENGTH)
		proof_height	= data[ID_LENGTH] || 0
		proof_length	= proof_height * (ID_LENGTH + 1)
		proof			= data.subarray(ID_LENGTH + 1, ID_LENGTH + 1 + proof_length)
		if proof.length != proof.length
			proof = null_array
		peers			= data.subarray(ID_LENGTH + 1 + proof_length)
		if peers.length % ID_LENGTH
			peers	= []
		else
			peers			=
				for i from 0 til peers.length / ID_LENGTH
					peers.subarray(ID_LENGTH * i, ID_LENGTH * (i + 1))
		[state_version, proof, peers]
	/**
	 * @constructor
	 *
	 * @param {number}	size
	 *
	 * @return {!Values_cache}
	 */
	!function Values_cache (size)
		if !(@ instanceof Values_cache)
			return new Values_cache(size)
		@_size	= size
		@_map	= ArrayMap()
	Values_cache:: =
		/**
		 * @param {!Uint8Array}	key
		 * @param {!Uint8Array}	value
		 */
		add : (key, value) !->
			if @_map.has(key)
				@_map.delete(key)
			@_map.set(key, value)
			if @_map.size > @_size
				# Delete first element in the map
				@_map.delete(@_map.keys().next().value)
		/**
		 * @param {!Uint8Array}	key
		 *
		 * @return {!Uint8Array}
		 */
		get : (key) ->
			value	= @_map.get(key)
			if value
				@_map.delete(key)
				@_map.set(key, value)
			value
	Object.defineProperty(Values_cache::, 'constructor', {value: Values_cache})
	/**
	 * @constructor
	 *
	 * @param {!Uint8Array}				dht_public_key						Ed25519 that corresponds to temporary user identity in DHT network
	 * @param {number}					bucket_size							Size of a bucket from Kademlia design
	 * @param {number}					state_history_size					How many versions of local history will be kept
	 * @param {number}					values_cache_size					How many values will be kept in cache
	 * @param {number}					fraction_of_nodes_from_same_peer	Max fraction of nodes originated from single peer allowed on lookup start
	 * @param {!Object<string, number>}	timeouts							Various timeouts and intervals used internally
	 *
	 * @return {!DHT}
	 */
	!function DHT (dht_public_key, bucket_size, state_history_size, values_cache_size, fraction_of_nodes_from_same_peer = 0.2, timeouts = {})
		if !(@ instanceof DHT)
			return new DHT(dht_public_key, bucket_size, state_history_size, values_cache_size, fraction_of_nodes_from_same_peer, timeouts)
		async-eventer.call(@)

		@_timeouts					= Object.assign({}, DEFAULT_TIMEOUTS, timeouts)
		@_dht						= es-dht(dht_public_key, blake2b_256, bucket_size, state_history_size, fraction_of_nodes_from_same_peer)
		# Start from random transaction number
		@_transactions_counter		= detox-utils['random_int'](0, 2 ** 16 - 1)
		@_transactions_in_progress	= new Map
		@_timeouts_in_progress		= new Set
		@_values					= Values_cache(values_cache_size)
		@_state_update_interval		= intervalSet(@_timeouts['STATE_UPDATE_INTERVAL'], !~>
			# Periodically fetch latest state from all peers
			for let peer_id in @'get_peers'()
				@_make_request(peer_id, COMMAND_GET_STATE, null_array, @_timeouts['GET_STATE_REQUEST_TIMEOUT'])
					.then (state) !~>
						if !@'set_peer'(peer_id, state)
							@_peer_error(peer_id)
					.catch (error) !->
						error_handler(error)
						@_peer_warning(peer_id)
		)

	DHT:: =
		/**
		 * @param {!Uint8Array}	peer_id
		 * @param {number}		command
		 * @param {!Uint8Array}	payload
		 */
		'receive' : (peer_id, command, payload) !->
			if @_destroyed
				return
			[transaction_id, data]	= parse_payload(payload)
			switch command
				case COMMAND_RESPONSE
					callback	= @_transactions_in_progress.get(transaction_id)
					if callback
						callback(peer_id, data)
				case COMMAND_GET_STATE
					# Support for getting latest state version with empty state version request
					if !data.length
						data	= null
						# Commit latest state, since it will be known to other peers
						@_dht['commit_state']()
					state	= @_get_state(data)
					if state
						@_make_response(peer_id, transaction_id, state)
				case COMMAND_GET_PROOF
					[state_version, node_id]	= parse_get_proof_request(data)
					@_make_response(peer_id, transaction_id, @_dht['get_state_proof'](state_version, node_id))
				case COMMAND_GET_VALUE
					value	= @_values.get(data)
					@_make_response(peer_id, transaction_id, value || null_array)
				case COMMAND_PUT_VALUE
					[key, payload]	= parse_put_value_request(data)
					if @'verify_value'(key, payload)
						@_values.add(key, payload)
					else
						@_peer_error(peer_id)
		/**
		 * @param {!Uint8Array} node_id
		 *
		 * @return {!Promise} Resolves with `!Array<!Uint8Array>`
		 */
		'lookup' : (node_id) ->
			if @_destroyed
				return Promise.reject()
			@_handle_lookup(node_id, @_dht['start_lookup'](node_id))
		/**
		 * @param {!Uint8Array}					node_id
		 * @param {!Array<!Array<!Uint8Array>>}	nodes_to_connect_to
		 *
		 * @return {!Promise}
		 */
		_handle_lookup : (node_id, nodes_to_connect_to) ->
			if @_destroyed
				return Promise.reject()
			new Promise (resolve, reject) !~>
				if !nodes_to_connect_to.length
					found_nodes	= @_dht['finish_lookup'](node_id)
					if found_nodes
						resolve(found_nodes)
					else
						reject()
					return
				nodes_for_next_round	= []
				pending					= nodes_to_connect_to.length
				!~function done
					pending--
					if !pending
						@_handle_lookup(node_id, nodes_for_next_round).then(resolve)
				for let [target_node_id, parent_node_id, parent_state_version] in nodes_to_connect_to
					@_make_request(parent_node_id, COMMAND_GET_PROOF, compose_get_proof_request(parent_state_version, target_node_id), @_timeouts['GET_PROOF_REQUEST_TIMEOUT'])
						.then (proof) !~>
							target_node_state_version	= @_dht['check_state_proof'](parent_state_version, proof, target_node_id)
							if target_node_state_version
								@_connect_to(target_node_id, parent_node_id).then ~>
									@_make_request(target_node_id, COMMAND_GET_STATE, target_node_state_version, @_timeouts['GET_STATE_REQUEST_TIMEOUT'])
										.then(parse_state)
										.then ([state_version, proof, peers]) !~>
											proof_check_result	= @_dht['check_state_proof'](state_version, proof, target_node_id)
											if (
												are_arrays_equal(target_node_state_version, state_version) &&
												proof_check_result &&
												are_arrays_equal(proof_check_result, target_node_id)
											)
												nodes_for_next_round	:= nodes_for_next_round.concat(
													@_dht['update_lookup'](node_id, target_node_id, target_node_state_version, peers)
												)
											else
												@_peer_error(target_node_id)
											done()
										.catch (error) !->
											error_handler(error)
											@_peer_warning(target_node_id)
											done()
							else
								@_peer_error(parent_node_id)
								done()
						.catch (error) !->
							error_handler(error)
							@_peer_warning(parent_node_id)
							done()
		/**
		 * @param {!Uint8Array} peer_id
		 */
		_peer_error : (peer_id) !->
			# Notify higher level about peer error, error is a strong indication of malicious node, stop communicating immediately
			@'fire'('peer_error', peer_id)
			@'del_peer'(peer_id)
		/**
		 * @param {!Uint8Array} peer_id
		 */
		_peer_warning : (peer_id) !->
			# Notify higher level about peer warning, warning is a potential indication of malicious node, but threshold must be implemented on higher level
			@'fire'('peer_warning', peer_id)
		/**
		 * @param {!Uint8Array}	peer_peer_id	Peer's peer ID
		 * @param {!Uint8Array}	peer_id			Peer ID
		 *
		 * @return {!Promise}
		 */
		_connect_to : (peer_peer_id, peer_id) ->
			@'fire'('connect_to', peer_peer_id, peer_id)
		/**
		 * @return {!Uint8Array}
		 */
		'get_state' : ->
			@_get_state()
		/**
		 * @param {Uint8Array=} state_version	Specific state version or latest if `null`
		 *
		 * @return {!Uint8Array}
		 */
		_get_state : (state_version = null) ->
			if @_destroyed
				return null_array
			[state_version, proof, peers]	= @_dht['get_state'](state_version)
			compose_state(state_version, proof, peers)
		/**
		 * @return {!Array<!Uint8Array>}
		 */
		'get_peers' : ->
			if @_destroyed
				return []
			@_dht['get_state']()[2]
		/**
		 * @param {!Uint8Array}	peer_id	Id of a peer
		 * @param {!Uint8Array}	state	Peer's state generated with `get_state()` method
		 *
		 * @return {boolean} `false` if state proof is not valid, returning `true` only means there was not errors, but peer was not necessarily added to
		 *                   k-bucket (use `has_peer()` method if confirmation of addition to k-bucket is needed)
		 */
		'set_peer' : (peer_id, state) ->
			if @_destroyed
				return false
			[peer_state_version, proof, peer_peers]	= parse_state(state)
			result	= @_dht['set_peer'](peer_id, peer_state_version, proof, peer_peers)
			if !result
				@_peer_error(peer_id)
			result
		/**
		 * @param {!Uint8Array} node_id
		 *
		 * @return {boolean} `true` if `node_id` is our peer (stored in k-bucket)
		 */
		'has_peer' : (node_id) ->
			if @_destroyed
				return false
			@_dht['has_peer'](node_id)
		/**
		 * @param {!Uint8Array} peer_id Id of a peer
		 */
		'del_peer' : (peer_id) !->
			if @_destroyed
				return
			@_dht['del_peer'](peer_id)
		/**
		 * @param {!Uint8Array} key
		 *
		 * @return {!Promise} Resolves with value on success
		 */
		'get_value' : (key) ->
			if @_destroyed
				return Promise.reject()
			value	= @_values.get(key)
			# Return immutable value from cache immediately, but for mutable try to find never version first
			if value && are_arrays_equal(blake2b_256(value), key)
				return Promise.resolve(value)
			@'lookup'(key).then (peers) ~>
				new Promise (resolve, reject) !~>
					pending	= peers.length
					stop	= false
					found	=
						if value
							@_verify_mutable_value(key, value)
						else
							null
					if !peers.length
						finish()
					!function done
						if stop
							return
						pending--
						if !pending
							finish()
					!function finish
						if !found
							reject()
						else
							resolve(found[1])
					for peer_id in peers
						@_make_request(peer_id, COMMAND_GET_VALUE, key, @_timeouts['GET_VALUE_TIMEOUT'])
							.then (data) !~>
								if stop
									return
								if !data.length # Node doesn't own requested value
									done()
									return
								# Immutable values can be returned immediately
								if are_arrays_equal(blake2b_256(data), key)
									stop	:= true
									resolve(data)
									return
								# Mutable values will have version, so we wait and pick value with higher version
								payload	= @_verify_mutable_value(key, data)
								if payload
									if !found || found[0] < payload[0]
										found	:= payload
								else
									@_peer_error(peer_id)
								done()
							.catch (error) !->
								error_handler(error)
								@_peer_warning(peer_id)
								done()
		/**
		 * @param {!Uint8Array} key
		 * @param {!Uint8Array} data
		 *
		 * @return {Array} `[version, value]` if signature is correct or `null` otherwise
		 */
		_verify_mutable_value : (key, data) ->
			# Version is 4 bytes, so there should be at least 1 byte of useful payload
			if data.length < (SIGNATURE_LENGTH + 5)
				return null
			payload		= data.subarray(0, data.length - SIGNATURE_LENGTH)
			signature	= data.subarray(data.length - SIGNATURE_LENGTH)
			if !verify_signature(signature, payload, key)
				return null
			parse_mutable_value(payload)
		/**
		 * @param {!Uint8Array} value
		 *
		 * @return {Array<!Uint8Array>} `[key, data]`, can be placed into DHT with `put_value()` method or `null` if value is too big to be stored in DHT
		 */
		'make_immutable_value' : (value) ->
			if value.length > MAX_VALUE_LENGTH
				return null
			key	= blake2b_256(value)
			[key, value]
		/**
		 * @param {!Uint8Array}	public_key	Ed25519 public key, will be used as key for data
		 * @param {!Uint8Array}	private_key	Ed25519 private key
		 * @param {number}		version		Up to 32-bit number
		 * @param {!Uint8Array}	value
		 *
		 * @return {Array<!Uint8Array>} `[key, data]`, can be placed into DHT with `put_value()` method or `null` if value is too big to be stored in DHT
		 */
		'make_mutable_value' : (public_key, private_key, version, value) ->
			if value.length > MAX_VALUE_LENGTH
				return null
			payload		= compose_mutable_value(version, value)
			signature	= create_signature(payload, public_key, private_key)
			data		= concat_arrays([payload, signature])
			[public_key, data]
		/**
		 * @param {!Uint8Array} key
		 * @param {!Uint8Array} data
		 *
		 * @return {Uint8Array} `value` if correct data and `null` otherwise
		 */
		'verify_value' : (key, data) ->
			if are_arrays_equal(blake2b_256(data), key) && data.length <= MAX_VALUE_LENGTH
				return data
			payload = @_verify_mutable_value(key, data)
			if payload && payload[1].length <= MAX_VALUE_LENGTH
				payload[1]
			else
				null
		/**
		 * @param {!Uint8Array} key		As returned by `make_*_value()` methods
		 * @param {!Uint8Array} data	As returned by `make_*_value()` methods
		 *
		 * @return {!Promise}
		 */
		'put_value' : (key, data) ->
			if @_destroyed
				return Promise.reject()
			if !@'verify_value'(key, data)
				return Promise.reject()
			@_values.add(key, data)
			@'lookup'(key).then (peers) ~>
				if !peers.length
					return
				command_data	= compose_put_value_request(key, data)
				for peer_id in peers
					@_make_request(peer_id, COMMAND_PUT_VALUE, command_data, @_timeouts['PUT_VALUE_TIMEOUT'])
		'destroy' : ->
			if @_destroyed
				return
			@_destroyed	= true
			@_timeouts_in_progress.forEach(clearTimeout)
			clearInterval(@_state_update_interval)
		/**
		 * @param {!Uint8Array}	peer_id
		 * @param {number}		command
		 * @param {!Uint8Array}	data
		 * @param {number}		request_timeout	In seconds
		 *
		 * @return {!Promise} Will resolve with data received from `peer_id`'s response or will reject on timeout
		 */
		_make_request : (peer_id, command, data, request_timeout) ->
			promise	= new Promise (resolve, reject) !~>
				transaction_id	= @_generate_transaction_id()
				@_transactions_in_progress.set(transaction_id, (peer_id, data) !~>
					if are_arrays_equal(peer_id, peer_id)
						clearTimeout(timeout)
						@_timeouts_in_progress.delete(timeout)
						@_transactions_in_progress.delete(transaction_id)
						resolve(data)
				)
				timeout = timeoutSet(request_timeout, !~>
					@_transactions_in_progress.delete(transaction_id)
					@_timeouts_in_progress.delete(timeout)
					reject()
				)
				@_timeouts_in_progress.add(timeout)
				@_send(peer_id, command, compose_payload(transaction_id, data))
			# In case the code that made request doesn't expect response and didn't add `catch()` itself
			promise.catch(error_handler)
			promise
		/**
		 * @param {!Uint8Array}	peer_id
		 * @param {number}		transaction_id
		 * @param {!Uint8Array}	data
		 */
		_make_response : (peer_id, transaction_id, data) !->
			@_send(peer_id, COMMAND_RESPONSE, compose_payload(transaction_id, data))
		/**
		 * @return {number} From range `[0, 2 ** 16)`
		 */
		_generate_transaction_id : ->
			transaction_id = @_transactions_counter
			@_transactions_counter++
			if @_transactions_counter == 2 ** 16 # Overflow, start from 0
				@_transactions_counter = 0
			transaction_id
		/**
		 * @param {!Uint8Array}	peer_id
		 * @param {number}		command
		 * @param {!Uint8Array}	payload
		 */
		_send : (peer_id, command, payload) !->
			@'fire'('send', peer_id, command, payload)

	DHT:: = Object.assign(Object.create(async-eventer::), DHT::)
	Object.defineProperty(DHT::, 'constructor', {value: DHT})

	{
		'ready'				: detox-crypto['ready']
		'DHT'				: DHT
		'MAX_VALUE_LENGTH'	: MAX_VALUE_LENGTH
	}

if typeof define == 'function' && define['amd']
	# AMD
	define(['@detox/crypto', '@detox/utils', 'async-eventer', 'es-dht'], Wrapper)
else if typeof exports == 'object'
	# CommonJS
	module.exports = Wrapper(require('@detox/crypto'), require('@detox/utils'), require('async-eventer'), require('es-dht'))
else
	# Browser globals
	@'detox_dht' = Wrapper(@'detox_crypto', @'detox_utils', 'async_eventer', @'es_dht')
