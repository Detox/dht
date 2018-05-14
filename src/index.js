// Generated by LiveScript 1.5.0
/**
 * @package Detox DHT
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
(function(){
  var ID_LENGTH, COMMAND_RESPONSE, COMMAND_GET_STATE, COMMAND_GET_PROOF, COMMAND_MAKE_CONNECTION, GET_PROOF_REQUEST_TIMEOUT, MAKE_CONNECTION_REQUEST_TIMEOUT, GET_STATE_REQUEST_TIMEOUT;
  ID_LENGTH = 32;
  COMMAND_RESPONSE = 0;
  COMMAND_GET_STATE = 1;
  COMMAND_GET_PROOF = 2;
  COMMAND_MAKE_CONNECTION = 3;
  GET_PROOF_REQUEST_TIMEOUT = 5;
  MAKE_CONNECTION_REQUEST_TIMEOUT = 10;
  GET_STATE_REQUEST_TIMEOUT = 5;
  /**
   * @param {!Uint8Array} state_version
   * @param {!Uint8Array} node_id
   *
   * @return {!Uint8Array}
   */
  function compose_get_proof_request(state_version, node_id){
    var x$;
    x$ = new Uint8Array(ID_LENGTH * 2);
    x$.set(node_id, ID_LENGTH);
    x$.set(state_version);
    return x$;
  }
  /**
   * @param {!Uint8Array} data
   *
   * @return {!Array<!Uint8Array>} `[state_version, node_id]`
   */
  function parse_get_proof_request(data){
    var state_version, node_id;
    state_version = data.subarray(0, ID_LENGTH);
    node_id = data.subarray(ID_LENGTH);
    return [state_version, node_id];
  }
  /**
   * @param {!Uint8Array} node_id
   * @param {!Uint8Array} connection_details
   *
   * @return {!Uint8Array}
   */
  function compose_make_connection_request(node_id, connection_details){
    var x$;
    x$ = new Uint8Array(ID_LENGTH * 2);
    x$.set(node_id);
    x$.set(connection_details, ID_LENGTH);
    return x$;
  }
  /**
   * @param {!Uint8Array} data
   *
   * @return {!Array<!Uint8Array>} `[node_id, connection_details]`
   */
  function parse_make_connection_request(data){
    var node_id, connection_details;
    node_id = data.subarray(0, ID_LENGTH);
    connection_details = data.subarray(ID_LENGTH);
    return [node_id, connection_details];
  }
  /**
   * @param {number}		transaction_id
   * @param {!Uint8Array}	data
   *
   * @return {!Uint8Array}
   */
  function compose_payload(transaction_id, data){
    var x$, array, y$;
    x$ = array = new Uint8Array(2 + data.length);
    x$.set(data, 2);
    y$ = new DataView(array.buffer);
    y$.setUint16(0, transaction_id, false);
    return array;
  }
  /**
   * @param {!Uint8Array} payload
   *
   * @return {!Array<!Uint8Array>} `[transaction_id, data]`
   */
  function parse_payload(payload){
    var view, transaction_id, data;
    view = new DataView(payload.buffer, payload.byteOffset, payload.byteLength);
    transaction_id = view.getUint16(0, false);
    data = payload.subarray(2);
    return [transaction_id, data];
  }
  function Wrapper(detoxCrypto, detoxUtils, asyncEventer, esDht){
    var are_arrays_equal, concat_arrays, timeoutSet;
    are_arrays_equal = detoxUtils['are_arrays_equal'];
    concat_arrays = detoxUtils['concat_arrays'];
    timeoutSet = detoxUtils['timeoutSet'];
    /**
     * @param {!Uint8Array}			state_version
     * @param {!Uint8Array}			proof
     * @param {!Array<!Uint8Array>}	peers
     *
     * @return {!Uint8Array}
     */
    function compose_get_state_response(state_version, proof, peers){
      var proof_height, x$;
      proof_height = proof.length / (ID_LENGTH + 1);
      peers = concat_arrays(peers);
      x$ = new Uint8Array(ID_LENGTH + proof.length + peers.length);
      x$.set(state_version);
      x$.set([proof_height], ID_LENGTH);
      x$.set(proof, ID_LENGTH + 1);
      x$.set(peers, ID_LENGTH + 1 + proof.length);
      return x$;
    }
    /**
     * @param {!Uint8Array} data
     *
     * @return {!Array} `[state_version, proof, peers]`
     */
    function parse_get_state_response(data){
      var state_version, proof_height, proof_length, proof, peers, res$, i$, to$, i;
      state_version = data.subarray(0, ID_LENGTH);
      proof_height = data[ID_LENGTH] || 0;
      proof_length = proof_height * (ID_LENGTH + 1);
      proof = data.subarray(ID_LENGTH + 1, ID_LENGTH + 1 + proof_length);
      if (proof.length !== proof.length) {
        proof = new Uint8Array(0);
      }
      peers = data.subarray(ID_LENGTH + 1 + proof_length);
      if (peers.length % ID_LENGTH) {
        peers = [];
      } else {
        res$ = [];
        for (i$ = 0, to$ = peers.length / ID_LENGTH; i$ < to$; ++i$) {
          i = i$;
          res$.push(peers.subarray(ID_LENGTH * i, ID_LENGTH * (i + 1)));
        }
        peers = res$;
      }
      return [state_version, proof, peers];
    }
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
    function DHT(dht_public_key, bootstrap_nodes, hash_function, verify, bucket_size, state_history_size, fraction_of_nodes_from_same_peer){
      var i$, len$, bootstrap_node;
      fraction_of_nodes_from_same_peer == null && (fraction_of_nodes_from_same_peer = 0.2);
      if (!(this instanceof DHT)) {
        return new DHT(dht_public_key, bootstrap_nodes, hash_function, verify, bucket_size, state_history_size, fraction_of_nodes_from_same_peer);
      }
      asyncEventer.call(this);
      this._dht = esDht(dht_public_key, hash_function, bucket_size, state_history_size, fraction_of_nodes_from_same_peer);
      this._transactions_counter = detoxUtils['random_int'](0, Math.pow(2, 16) - 1);
      this._transactions_in_progress = new Map;
      this._timeouts = new Set;
      for (i$ = 0, len$ = bootstrap_nodes.length; i$ < len$; ++i$) {
        bootstrap_node = bootstrap_nodes[i$];
      }
    }
    DHT.prototype = {
      'receive': function(source_id, command, payload){
        var ref$, transaction_id, data, callback, state_version, node_id;
        ref$ = parse_payload(payload), transaction_id = ref$[0], data = ref$[1];
        switch (command) {
        case COMMAND_RESPONSE:
          callback = this._transactions_in_progress.get(transaction_id);
          if (callback) {
            callback(source_id, data);
          }
          break;
        case COMMAND_GET_STATE:
          break;
        case COMMAND_GET_PROOF:
          ref$ = parse_get_proof_request(data), state_version = ref$[0], node_id = ref$[1];
          this._make_response(source_id, transaction_id, this._dht['get_state_proof'](state_version, node_id));
          break;
        case COMMAND_MAKE_CONNECTION:
        }
      }
      /**
       * @param {!Uint8Array}	seed			Seed used to generate bootstrap node's keys (it may be different from `dht_public_key` in constructor for scalability purposes
       * @param {string}		ip				IP on which to listen
       * @param {number}		port			Port on which to listen
       * @param {string=}		public_address	Publicly reachable address (can be IP or domain name) reachable
       * @param {number=}		public_port		Port that corresponds to `public_address`
       */,
      'listen': function(seed, ip, port, public_address, public_port){
        var keypair;
        public_address == null && (public_address = ip);
        public_port == null && (public_port = port);
        return keypair = detoxCrypto['create_keypair'](seed);
      }
      /**
       * @param {!Uint8Array} id
       *
       * @return {!Promise}
       */,
      'lookup': function(id){
        return this._handle_lookup(id, this._dht['start_lookup'](id));
      }
      /**
       * @param {!Uint8Array}					id
       * @param {!Array<!Array<!Uint8Array>>}	nodes_to_connect_to
       *
       * @return {!Promise}
       */,
      _handle_lookup: function(id, nodes_to_connect_to){
        var this$ = this;
        return new Promise(function(resolve, reject){
          var found_nodes, nodes_for_next_round, pending, i$, ref$, len$;
          if (!nodes_to_connect_to.length) {
            found_nodes = this$._dht['finish_lookup'](id);
            if (found_nodes) {
              resolve(found_nodes);
            } else {
              reject();
            }
            return;
          }
          nodes_for_next_round = [];
          pending = nodes_to_connect_to.length;
          function done(){
            pending--;
            if (!pending) {
              return this._handle_lookup(id, nodes_for_next_round);
            }
          }
          for (i$ = 0, len$ = (ref$ = nodes_to_connect_to).length; i$ < len$; ++i$) {
            (fn$.call(this$, ref$[i$]));
          }
          function fn$(arg$){
            var target_node_id, parent_node_id, parent_state_version, this$ = this;
            target_node_id = arg$[0], parent_node_id = arg$[1], parent_state_version = arg$[2];
            this._make_request(parent_node_id, COMMAND_GET_PROOF, compose_get_proof_request(parent_state_version, target_node_id), GET_PROOF_REQUEST_TIMEOUT).then(function(proof){
              var target_node_state_version;
              target_node_state_version = this$._dht['check_state_proof'](parent_state_version, parent_node_id, proof, target_node_id);
              if (target_node_state_version) {
                this$._initiate_p2p_connection().then(function(local_connection_details){
                  return this$._make_request(parent_node_id, COMMAND_MAKE_CONNECTION, compose_make_connection_request(target_node_id, local_connection_details), MAKE_CONNECTION_REQUEST_TIMEOUT).then(function(remote_connection_details){
                    return this$._establish_p2p_connection(local_connection_details, remote_connection_details);
                  });
                }).then(function(){
                  return this$._make_request(target_node_id, COMMAND_GET_STATE, target_node_state_version, GET_STATE_REQUEST_TIMEOUT).then(parse_get_state_response).then(function(arg$){
                    var state_version, proof, peers;
                    state_version = arg$[0], proof = arg$[1], peers = arg$[2];
                    if (this$._dht['check_state_proof'](state_version, target_node_id, proof, target_node_id)) {
                      nodes_for_next_round = nodes_for_next_round.concat(this$._dht['update_lookup'](id, target_node_id, target_node_state_version, peers));
                    }
                    done();
                  });
                });
              } else {
                done();
              }
            })['catch'](function(){
              done();
            });
          }
        });
      }
      /**
       * @return {!Promise} Resolves with `local_connection_details`
       */,
      _initiate_p2p_connection: function(){
        var data;
        data = {
          'connection_details': null
        };
        return this['fire']('initiate_connection', data).then(function(){
          if (!data['connection_details']) {
            throw '';
          }
          return data['connection_details'];
        });
      }
      /**
       * @return {!Promise}
       */,
      _establish_p2p_connection: function(local_connection_details, remote_connection_details){
        return this['fire']('establish_connection', local_connection_details, remote_connection_details);
      }
      /**
       * @return {!Array<!Uint8Array>}
       */,
      'get_peers': function(){}
      /**
       * @param {!Uint8Array} key
       *
       * @return {!Promise}
       */,
      'get': function(key){}
      /**
       * @param {!Uint8Array} data
       *
       * @return {!Uint8Array} Key
       */,
      'put_immutable': function(data){}
      /**
       * @param {!Uint8Array} public_key
       * @param {!Uint8Array} data
       * @param {!Uint8Array} signature
       */,
      'put_mutable': function(public_key, data, signature){},
      'destroy': function(){
        this._destroyed = true;
        return this._timeouts.forEach(clearTimeout);
      }
      /**
       * @param {!Uint8Array}	target_id
       * @param {number}		command
       * @param {!Uint8Array}	data
       * @param {number}		timeout		In seconds
       *
       * @return {!Promise} Will resolve with data received from `target_id`'s response or will reject on timeout
       */,
      _make_request: function(target_id, command, data, timeout){
        var this$ = this;
        return new Promise(function(resolve, reject){
          var transaction_id, timeout;
          transaction_id = this$._transactions_counter();
          this$._transactions_in_progress.set(transaction_id, function(source_id, data){
            if (are_arrays_equal(target_id, source_id)) {
              clearTimeout(timeout);
              this._timeouts['delete'](timeout);
              this._transactions_in_progress['delete'](transaction_id);
              return resolve(data);
            }
          });
          timeout = timeoutSet(timeout, function(){
            this$._transactions_in_progress['delete'](transaction_id);
            this$._timeouts['delete'](timeout);
            reject();
          });
          this$._timeouts.add(timeout);
          this$._send(target_id, command, compose_payload(transaction_id, data));
        });
      }
      /**
       * @param {!Uint8Array}	target_id
       * @param {number}		transaction_id
       * @param {!Uint8Array}	data
       */,
      _make_response: function(target_id, transaction_id, data){
        this._send(target_id, COMMAND_RESPONSE, compose_payload(transaction_id, data));
      }
      /**
       * @return {number} From range `[0, 2 ** 16)`
       */,
      _generate_transaction_id: function(){
        var transaction_id;
        transaction_id = this._transactions_counter;
        this._transactions_counter++;
        if (this._transactions_counter === Math.pow(2, 16)) {
          this._transactions_counter = 0;
        }
        return transaction_id;
      }
      /**
       * @param {!Uint8Array} target_id
       * @param {!Uint8Array} command
       * @param {!Uint8Array} payload
       */,
      _send: function(target_id, command, payload){
        this['fire']('send', target_id, command, payload);
      }
    };
    DHT.prototype = Object.assign(Object.create(asyncEventer.prototype), DHT.prototype);
    Object.defineProperty(DHT.prototype, 'constructor', {
      value: DHT
    });
    return {
      'ready': detoxCrypto['ready'],
      'DHT': DHT
    };
  }
  if (typeof define === 'function' && define['amd']) {
    define(['@detox/crypto', '@detox/utils', 'async-eventer', 'es-dht'], Wrapper);
  } else if (typeof exports === 'object') {
    module.exports = Wrapper(require('@detox/crypto'), require('@detox/utils'), require('async-eventer'), require('es-dht'));
  } else {
    this['detox_dht'] = Wrapper(this['detox_crypto'], this['detox_utils'], 'async_eventer', this['es_dht']);
  }
}).call(this);
