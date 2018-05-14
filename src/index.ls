/**
 * @package Detox DHT
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
const ID_LENGTH							= 32
const SIGNATURE_LENGTH					= 64
const COMMAND_RESPONSE					= 0
const COMMAND_GET_STATE					= 1
const COMMAND_GET_PROOF					= 2
# Would be nice to make these configurable on instance level
const GET_PROOF_REQUEST_TIMEOUT			= 5
const MAKE_CONNECTION_REQUEST_TIMEOUT	= 10
const GET_STATE_REQUEST_TIMEOUT			= 5
const GET_TIMEOUT						= 5
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
 * @return {!Array<!Uint8Array>} `[transaction_id, data]`
 */
function parse_payload (payload)
	view			= new DataView(payload.buffer, payload.byteOffset, payload.byteLength)
	transaction_id	= view.getUint16(0, false)
	data			= payload.subarray(2)
	[transaction_id, data]
/**
 * @param {number}		version
 * @param {!Uint8Array}	data
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
 * @return {!Array<!Uint8Array>} `[version, value]`
 */
function parse_mutable_value (payload)
	view	= new DataView(payload.buffer, payload.byteOffset, payload.byteLength)
	version	= view.getUint32(0, false)
	value	= payload.subarray(4)
	[version, value]

function Wrapper (detox-crypto, detox-utils, async-eventer, es-dht)
	are_arrays_equal	= detox-utils['are_arrays_equal']
	concat_arrays		= detox-utils['concat_arrays']
	timeoutSet			= detox-utils['timeoutSet']

	/**
	 * @param {!Uint8Array}			state_version
	 * @param {!Uint8Array}			proof
	 * @param {!Array<!Uint8Array>}	peers
	 *
	 * @return {!Uint8Array}
	 */
	function compose_get_state_response (state_version, proof, peers)
		proof_height	= proof.length / (ID_LENGTH + 1)
		peers			= concat_arrays(peers)
		new Uint8Array(ID_LENGTH + proof.length + peers.length)
			..set(state_version)
			..set([proof_height], ID_LENGTH)
			..set(proof, ID_LENGTH + 1)
			..set(peers, ID_LENGTH + 1 + proof.length)
	/**
	 * @param {!Uint8Array} data
	 *
	 * @return {!Array} `[state_version, proof, peers]`
	 */
	function parse_get_state_response (data)
		state_version	= data.subarray(0, ID_LENGTH)
		proof_height	= data[ID_LENGTH] || 0
		proof_length	= proof_height * (ID_LENGTH + 1)
		proof			= data.subarray(ID_LENGTH + 1, ID_LENGTH + 1 + proof_length)
		if proof.length != proof.length
			proof = new Uint8Array(0)
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
		 * @param {!Map}		value
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
		 * @return {!Map}
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
	 * @param {!Uint8Array}		dht_public_key						Own ID (Ed25519 public key)
	 * @param {!Array<!Object>}	bootstrap_nodes						Array of objects with keys (all of them are required) `node_id`, `host` and `port`
	 * @param {!Function}		hash_function						Hash function to be used for Merkle Tree
	 * @param {!Function}		verify_function						Function for verifying Ed25519 signatures, arguments are `Uint8Array`s `(signature, data, public_key)`
	 * @param {number}			bucket_size							Size of a bucket from Kademlia design
	 * @param {number}			state_history_size					How many versions of local history will be kept
	 * @param {number}			values_cache_size					How many values will be kept in cache
	 * @param {number}			fraction_of_nodes_from_same_peer	Max fraction of nodes originated from single peer allowed on lookup start
	 *
	 * @return {!DHT}
	 */
	!function DHT (dht_public_key, bootstrap_nodes, hash_function, verify_function, bucket_size, state_history_size, values_cache_size, fraction_of_nodes_from_same_peer = 0.2)
		if !(@ instanceof DHT)
			return new DHT(dht_public_key, bootstrap_nodes, hash_function, verify_function, bucket_size, state_history_size, values_cache_size, fraction_of_nodes_from_same_peer)
		async-eventer.call(@)

		@_dht						= es-dht(dht_public_key, hash_function, bucket_size, state_history_size, fraction_of_nodes_from_same_peer)
		@_hash						= hash_function
		@_verify					= verify_function
		# Start from random transaction number
		@_transactions_counter		= detox-utils['random_int'](0, 2 ** 16 - 1)
		@_transactions_in_progress	= new Map
		@_timeouts					= new Set
		@_values					= Values_cache(values_cache_size)
		for bootstrap_node in bootstrap_nodes
			void # TODO: Bootstrap

	DHT:: =
		'receive' : (source_id, command, payload) !->
			[transaction_id, data]	= parse_payload(payload)
			switch command
				case COMMAND_RESPONSE
					callback	= @_transactions_in_progress.get(transaction_id)
					if callback
						callback(source_id, data)
				case COMMAND_GET_STATE
					state	= @_dht['get_state'](data)
					if state
						@_make_response(source_id, transaction_id, compose_get_state_response(state))
				case COMMAND_GET_PROOF
					[state_version, node_id]	= parse_get_proof_request(data)
					@_make_response(source_id, transaction_id, @_dht['get_state_proof'](state_version, node_id))
				case COMMAND_GET
					value	= @_values.get(data)
					@_make_response(source_id, transaction_id, value || new Uint8Array(0))
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
			@_handle_lookup(id, @_dht['start_lookup'](id))
		/**
		 * @param {!Uint8Array}					id
		 * @param {!Array<!Array<!Uint8Array>>}	nodes_to_connect_to
		 *
		 * @return {!Promise}
		 */
		_handle_lookup : (id, nodes_to_connect_to) ->
			new Promise (resolve, reject) !~>
				if !nodes_to_connect_to.length
					found_nodes	= @_dht['finish_lookup'](id)
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
						@_handle_lookup(id, nodes_for_next_round)
				for let [target_node_id, parent_node_id, parent_state_version] in nodes_to_connect_to
					@_make_request(parent_node_id, COMMAND_GET_PROOF, compose_get_proof_request(parent_state_version, target_node_id), GET_PROOF_REQUEST_TIMEOUT)
						.then (proof) !~>
							target_node_state_version	= @_dht['check_state_proof'](parent_state_version, parent_node_id, proof, target_node_id)
							if target_node_state_version
								@_connect_to(target_node_id, parent_node_id).then ~>
									@_make_request(target_node_id, COMMAND_GET_STATE, target_node_state_version, GET_STATE_REQUEST_TIMEOUT)
										.then(parse_get_state_response)
										.then ([state_version, proof, peers]) !~>
											if @_dht['check_state_proof'](state_version, target_node_id, proof, target_node_id)
												nodes_for_next_round	:= nodes_for_next_round.concat(
													@_dht['update_lookup'](id, target_node_id, target_node_state_version, peers)
												)
											done()
							else
								# TODO: Drop connection on bad proof (also take into account timeouts, since peer may just refuse to answer)
								done()
						.catch !->
							done()
		/**
		 * @param {!Uint8Array}	peer_peer_id	Peer's peer ID
		 * @param {!Uint8Array}	peer_id			Peer ID
		 *
		 * @return {!Promise}
		 */
		_connect_to : (peer_peer_id, peer_id) ->
			@'fire'('connect_to', peer_peer_id, peer_id)
		/**
		 * @return {!Array<!Uint8Array>}
		 */
		'get_peers' : ->
			@_dht['get_state'][2]
		/**
		 * @param {!Uint8Array} key
		 *
		 * @return {!Promise}
		 */
		'get' : (key) ->
			value	= @_values.get(key)
			if value
				return Promise.resolve(value)
			@'lookup'(key).then (nodes) ~>
				new Promise (resolve, reject) !~>
					pending	= nodes.length
					stop	= false
					found	= null
					!function done
						if stop
							return
						pending--
						if !found && !pending
							reject()
						else
							resolve(found[1])
					for node_id in nodes
						@_make_request(node_id, COMMAND_GET, key, GET_TIMEOUT)
							.then (data) !~>
								if stop
									return
								# Immutable values can be returned immediately
								if are_arrays_equal(@_hash(data), key)
									stop	:= true
									resolve(data)
									return
								# Mutable values will have version, so we wait and pick value with higher version
								payload	= @_verify_mutable_value(key, data)
								if payload
									if !found || found[0] < payload[0]
										found	:= payload
								done()
							.catch(done)
		/**
		 * @param {!Uint8Array} key
		 * @param {!Uint8Array} data
		 *
		 * @return {Array} `[version, value]` if signature is correct or `null` otherwise
		 */
		_verify_mutable_value : (key, data) ->
			# Version is 4 bytes, so there should be at least 1 byte of useful payload
			if value.length < (SIGNATURE_LENGTH + 5)
				return null
			payload		= value.subarray(0, value.length - SIGNATURE_LENGTH)
			signature	= value.subarray(value.length - SIGNATURE_LENGTH)
			if !@_verify(signature, payload, key)
				return null
			parse_mutable_value(payload)
		/**
		 * @param {!Uint8Array} value
		 *
		 * @return {!Uint8Array} Key
		 */
		'put_immutable' : (value) ->
			# TODO: Configurable data size limit
			key	= @_hash(value)
			@_values.add(key, value)
			# TODO:
			key
		/**
		 * @param {!Uint8Array}	public_key
		 * @param {number}		version
		 * @param {!Uint8Array}	value
		 * @param {!Uint8Array}	signature
		 */
		'put_mutable' : (public_key, version, value, signature) !->
			# TODO
		'destroy' : ->
			# TODO: Check this property in relevant places
			@_destroyed	= true
			@_timeouts.forEach(clearTimeout)
		/**
		 * @param {!Uint8Array}	target_id
		 * @param {number}		command
		 * @param {!Uint8Array}	data
		 * @param {number}		timeout		In seconds
		 *
		 * @return {!Promise} Will resolve with data received from `target_id`'s response or will reject on timeout
		 */
		_make_request : (target_id, command, data, timeout) ->
			new Promise (resolve, reject) !~>
				transaction_id	= @_transactions_counter()
				@_transactions_in_progress.set(transaction_id, (source_id, data) ->
					if are_arrays_equal(target_id, source_id)
						clearTimeout(timeout)
						@_timeouts.delete(timeout)
						@_transactions_in_progress.delete(transaction_id)
						resolve(data)
				)
				timeout = timeoutSet(timeout, !~>
					@_transactions_in_progress.delete(transaction_id)
					@_timeouts.delete(timeout)
					reject()
				)
				@_timeouts.add(timeout)
				@_send(target_id, command, compose_payload(transaction_id, data))
		/**
		 * @param {!Uint8Array}	target_id
		 * @param {number}		transaction_id
		 * @param {!Uint8Array}	data
		 */
		_make_response : (target_id, transaction_id, data) !->
			@_send(target_id, COMMAND_RESPONSE, compose_payload(transaction_id, data))
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
		 * @param {!Uint8Array} target_id
		 * @param {!Uint8Array} command
		 * @param {!Uint8Array} payload
		 */
		_send : (target_id, command, payload) !->
			@'fire'('send', target_id, command, payload)

	DHT:: = Object.assign(Object.create(async-eventer::), DHT::)
	Object.defineProperty(DHT::, 'constructor', {value: DHT})

	{
		'ready'	: detox-crypto['ready']
		'DHT'	: DHT
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
