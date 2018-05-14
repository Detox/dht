/**
 * @package Detox DHT
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
const ID_LENGTH	= 32
# Would be nice to make these configurable on instance level
const GET_PROOF_REQUEST_TIMEOUT			= 5
const MAKE_CONNECTION_REQUEST_TIMEOUT	= 10
const GET_STATE_REQUEST_TIMEOUT			= 5
/**
 * @param {!Uint8Array} node_id
 * @param {!Uint8Array} state_version
 *
 * @return {!Uint8Array}
 */
function compose_get_proof_request (node_id, state_version)
	new Uint8Array(ID_LENGTH * 2)
		..set(node_id)
		..set(state_version, ID_LENGTH)
/**
 * @param {!Uint8Array} data
 *
 * @return {!Array<!Uint8Array>} `[node_id, state_version]`
 */
function parse_get_proof_request (data)
	node_id			= data.subarray(0, ID_LENGTH)
	state_version	= data.subarray(ID_LENGTH)
	[node_id, state_version]
/**
 * @param {!Uint8Array} node_id
 * @param {!Uint8Array} connection_details
 *
 * @return {!Uint8Array}
 */
function compose_make_connection_request (node_id, connection_details)
	new Uint8Array(ID_LENGTH * 2)
		..set(node_id)
		..set(connection_details, ID_LENGTH)
/**
 * @param {!Uint8Array} data
 *
 * @return {!Array<!Uint8Array>} `[node_id, connection_details]`
 */
function parse_make_connection_request (data)
	node_id				= data.subarray(0, ID_LENGTH)
	connection_details	= data.subarray(ID_LENGTH)
	[node_id, connection_details]

function Wrapper (detox-crypto, detox-utils, async-eventer, es-dht)
	concat_arrays	= detox-utils['concat_arrays']
	timeoutSet		= detox-utils['timeoutSet']

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
	 * @param {!Uint8Array}		dht_public_key						Own ID (Ed25519 public key)
	 * @param {!Array<!Object>}	bootstrap_nodes						Array of objects with keys (all of them are required) `node_id`, `host` and `port`
	 * @param {!Function}		hash_function						Hash function to be used for Merkle Tree
	 * @param {!Function}		verify								Function for verifying Ed25519 signatures, arguments are `Uint8Array`s `(signature, data. public_key)`
	 * @param {number}			bucket_size							Size of a bucket from Kademlia design
	 * @param {number}			state_history_size					How many versions of local history will be kept
	 * @param {number}			fraction_of_nodes_from_same_peer	Max fraction of nodes originated from single peer allowed on lookup start
	 *
	 * @return {!DHT}
	 */
	!function DHT (dht_public_key, bootstrap_nodes, hash_function, verify, bucket_size, state_history_size, fraction_of_nodes_from_same_peer = 0.2)
		if !(@ instanceof DHT)
			return new DHT(dht_public_key, bootstrap_nodes, hash_function, verify, bucket_size, state_history_size, fraction_of_nodes_from_same_peer)
		async-eventer.call(@)

		@_dht						= es-dht(dht_public_key, hash_function, bucket_size, state_history_size, fraction_of_nodes_from_same_peer)
		# Start from random transaction number
		@_transactions_counter		= detox-utils['random_int'](0, 2 ** 16 - 1)
		@_transactions_in_progress	= new Map
		@_timeouts					= new Set
		for bootstrap_node in bootstrap_nodes
			void # TODO: Bootstrap

	DHT:: =
		'handle_request' : (source_id, transaction_id, command, data) !->
			# TODO
		'handle_response' : (source_id, transaction_id, data) !->
			# TODO
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
				function done
					pending--
					if !pending
						@_handle_lookup(id, nodes_for_next_round)
				for let [target_node_id, parent_node_id, parent_state_version] in nodes_to_connect_to
					@_make_request(parent_node_id, 'get_proof', compose_get_proof_request(target_node_id, parent_state_version), GET_PROOF_REQUEST_TIMEOUT)
						.then (proof) !~>
							target_node_state_version	= @_dht['check_state_proof'](parent_state_version, parent_node_id, proof, target_node_id)
							if target_node_state_version
								@_initiate_p2p_connection()
									.then (local_connection_details) ~>
										@_make_request(parent_node_id, 'make_connection', compose_make_connection_request(target_node_id, local_connection_details), MAKE_CONNECTION_REQUEST_TIMEOUT)
											.then (remote_connection_details) ~>
												@_establish_p2p_connection(local_connection_details, remote_connection_details)
									.then ~>
										@_make_request(target_node_id, 'get_state', target_node_state_version, GET_STATE_REQUEST_TIMEOUT)
											.then(parse_get_state_response)
											.then ([state_version, proof, peers]) !~>
												if @_dht['check_state_proof'](state_version, target_node_id, proof, target_node_id)
													nodes_for_next_round	:= nodes_for_next_round.concat(
														@_dht['update_lookup'](id, target_node_id, target_node_state_version, peers)
													)
												done()
							else
								# TODO: Drop connection on bad proof
								done()
						.catch !->
							done()
		/**
		 * @return {!Promise} Resolves with `local_connection_details`
		 */
		_initiate_p2p_connection : ->
			# TODO
		/**
		 * @return {!Promise}
		 */
		_establish_p2p_connection : (local_connection_details, remote_connection_details) ->
			# TODO
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
			# TODO: Check this property in relevant places
			@_destroyed	= true
			@_timeouts.forEach(clearTimeout)
		/**
		 * @param {!Uint8Array}	target_id
		 * @param {string}		command
		 * @param {!Uint8Array}	data
		 * @param {number}		timeout		In seconds
		 *
		 * @return {!Promise} Will resolve with data received from `target_id`'s response or will reject on timeout
		 */
		_make_request : (target_id, command, data, timeout) ->
			new Promise (resolve, reject) !~>
				transaction_id	= @_transactions_counter()
				@_transactions_in_progress.set(transaction_id, (data) ->
					clearTimeout(timeout)
					@_timeouts.delete(timeout)
					resolve(data)
				)
				timeout = timeoutSet(timeout, !~>
					reject()
					@_transactions_in_progress.delete(transaction_id)
					@_timeouts.delete(timeout)
				)
				@_timeouts.add(timeout)
				@'fire'('request', target_id, transaction_id, command, data)
		/**
		 * @return {number} From range `[0, 2 ** 16)`
		 */
		_generate_transaction_id : ->
			transaction_id = @_transactions_counter
			@_transactions_counter++
			if @_transactions_counter == 2 ** 16 # Overflow, start from 0
				@_transactions_counter = 0
			transaction_id
		_make_response : (source_id, transaction_id, data) !->
			# TODO

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
