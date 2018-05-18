// Generated by LiveScript 1.5.0
/**
 * @package Detox DHT
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
(function(){
  var ID_LENGTH, SIGNATURE_LENGTH, COMMAND_RESPONSE, COMMAND_GET_STATE, COMMAND_GET_PROOF, COMMAND_GET_VALUE, COMMAND_PUT_VALUE, DEFAULT_TIMEOUTS;
  ID_LENGTH = 32;
  SIGNATURE_LENGTH = 64;
  COMMAND_RESPONSE = 0;
  COMMAND_GET_STATE = 1;
  COMMAND_GET_PROOF = 2;
  COMMAND_GET_VALUE = 3;
  COMMAND_PUT_VALUE = 4;
  DEFAULT_TIMEOUTS = {
    'GET_PROOF_REQUEST_TIMEOUT': 5,
    'GET_STATE_REQUEST_TIMEOUT': 10,
    'GET_VALUE_TIMEOUT': 5,
    'PUT_VALUE_TIMEOUT': 5,
    'STATE_UPDATE_INTERVAL': 15
  };
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
   * @return {!Array} `[transaction_id, data]`
   */
  function parse_payload(payload){
    var view, transaction_id, data;
    view = new DataView(payload.buffer, payload.byteOffset, payload.byteLength);
    transaction_id = view.getUint16(0, false);
    data = payload.subarray(2);
    return [transaction_id, data];
  }
  /**
   * @param {number}		version
   * @param {!Uint8Array}	data
   *
   * @return {!Uint8Array}
   */
  function compose_mutable_value(version, value){
    var x$, array, y$;
    x$ = array = new Uint8Array(4 + value.length);
    x$.set(value, 4);
    y$ = new DataView(array.buffer);
    y$.setUint32(0, version, false);
    return array;
  }
  /**
   * @param {!Uint8Array} payload
   *
   * @return {!Array} `[version, value]`
   */
  function parse_mutable_value(payload){
    var view, version, value;
    view = new DataView(payload.buffer, payload.byteOffset, payload.byteLength);
    version = view.getUint32(0, false);
    value = payload.subarray(4);
    return [version, value];
  }
  /**
   * @param {!Uint8Array} key
   * @param {!Uint8Array} payload
   *
   * @return {!Uint8Array}
   */
  function compose_put_value_request(key, payload){
    var x$;
    x$ = new Uint8Array(ID_LENGTH + payload.length);
    x$.set(key);
    x$.set(payload, ID_LENGTH);
    return x$;
  }
  /**
   * @param {!Uint8Array} data
   *
   * @return {!Array<!Uint8Array>} `[key, payload]`
   */
  function parse_put_value_request(data){
    var key, payload;
    key = data.subarray(0, ID_LENGTH);
    payload = data.subarray(ID_LENGTH);
    return [key, payload];
  }
  function Wrapper(detoxCrypto, detoxUtils, asyncEventer, esDht){
    var blake2b_256, create_signature, verify_signature, are_arrays_equal, concat_arrays, timeoutSet, intervalSet, ArrayMap, error_handler, null_array;
    blake2b_256 = detoxCrypto['blake2b_256'];
    create_signature = detoxCrypto['sign'];
    verify_signature = detoxCrypto['verify'];
    are_arrays_equal = detoxUtils['are_arrays_equal'];
    concat_arrays = detoxUtils['concat_arrays'];
    timeoutSet = detoxUtils['timeoutSet'];
    intervalSet = detoxUtils['intervalSet'];
    ArrayMap = detoxUtils['ArrayMap'];
    error_handler = detoxUtils['error_handler'];
    null_array = new Uint8Array(0);
    /**
     * @param {!Uint8Array}			state_version
     * @param {!Uint8Array}			proof
     * @param {!Array<!Uint8Array>}	peers
     *
     * @return {!Uint8Array}
     */
    function compose_state(state_version, proof, peers){
      var proof_height, x$;
      proof_height = proof.length / (ID_LENGTH + 1);
      peers = concat_arrays(peers);
      x$ = new Uint8Array(ID_LENGTH + 1 + proof.length + peers.length);
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
    function parse_state(data){
      var state_version, proof_height, proof_length, proof, peers, res$, i$, to$, i;
      state_version = data.subarray(0, ID_LENGTH);
      proof_height = data[ID_LENGTH] || 0;
      proof_length = proof_height * (ID_LENGTH + 1);
      proof = data.subarray(ID_LENGTH + 1, ID_LENGTH + 1 + proof_length);
      if (proof.length !== proof.length) {
        proof = null_array;
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
     * @param {number}	size
     *
     * @return {!Values_cache}
     */
    function Values_cache(size){
      if (!(this instanceof Values_cache)) {
        return new Values_cache(size);
      }
      this._size = size;
      this._map = ArrayMap();
    }
    Values_cache.prototype = {
      /**
       * @param {!Uint8Array}	key
       * @param {!Map}		value
       */
      add: function(key, value){
        if (this._map.has(key)) {
          this._map['delete'](key);
        }
        this._map.set(key, value);
        if (this._map.size > this._size) {
          this._map['delete'](this._map.keys().next().value);
        }
      }
      /**
       * @param {!Uint8Array}	key
       *
       * @return {!Map}
       */,
      get: function(key){
        var value;
        value = this._map.get(key);
        if (value) {
          this._map['delete'](key);
          this._map.set(key, value);
        }
        return value;
      }
    };
    Object.defineProperty(Values_cache.prototype, 'constructor', {
      value: Values_cache
    });
    /**
     * @constructor
     *
     * @param {!Uint8Array}				dht_public_key						Own ID (Ed25519 public key)
     * @param {number}					bucket_size							Size of a bucket from Kademlia design
     * @param {number}					state_history_size					How many versions of local history will be kept
     * @param {number}					values_cache_size					How many values will be kept in cache
     * @param {number}					fraction_of_nodes_from_same_peer	Max fraction of nodes originated from single peer allowed on lookup start
     * @param {!Object<string, number>}	timeouts							Various timeouts and intervals used internally
     *
     * @return {!DHT}
     */
    function DHT(dht_public_key, bucket_size, state_history_size, values_cache_size, fraction_of_nodes_from_same_peer, timeouts){
      var this$ = this;
      fraction_of_nodes_from_same_peer == null && (fraction_of_nodes_from_same_peer = 0.2);
      timeouts == null && (timeouts = {});
      if (!(this instanceof DHT)) {
        return new DHT(dht_public_key, bucket_size, state_history_size, values_cache_size, fraction_of_nodes_from_same_peer, timeouts);
      }
      asyncEventer.call(this);
      this._timeouts = Object.assign({}, DEFAULT_TIMEOUTS, timeouts);
      this._dht = esDht(dht_public_key, blake2b_256, bucket_size, state_history_size, fraction_of_nodes_from_same_peer);
      this._transactions_counter = detoxUtils['random_int'](0, Math.pow(2, 16) - 1);
      this._transactions_in_progress = new Map;
      this._timeouts_in_progress = new Set;
      this._values = Values_cache(values_cache_size);
      this._state_update_interval = intervalSet(this._timeouts['STATE_UPDATE_INTERVAL'], function(){
        var i$, ref$, len$;
        for (i$ = 0, len$ = (ref$ = this$['get_peers']()).length; i$ < len$; ++i$) {
          (fn$.call(this$, ref$[i$]));
        }
        function fn$(peer_id){
          var this$ = this;
          this._make_request(peer_id, COMMAND_GET_STATE, null_array, this._timeouts['GET_STATE_REQUEST_TIMEOUT']).then(function(state){
            if (!this$['set_peer'](peer_id, state)) {
              this$._peer_error(peer_id);
            }
          })['catch'](function(error){
            error_handler(error);
            this._peer_warning(peer_id);
          });
        }
      });
    }
    DHT.prototype = {
      /**
       * @param {!Uint8Array}	peer_id
       * @param {number}		command
       * @param {!Uint8Array}	payload
       */
      'receive': function(peer_id, command, payload){
        var ref$, transaction_id, data, callback, state, state_version, node_id, value, key;
        if (this._destroyed) {
          return;
        }
        ref$ = parse_payload(payload), transaction_id = ref$[0], data = ref$[1];
        switch (command) {
        case COMMAND_RESPONSE:
          callback = this._transactions_in_progress.get(transaction_id);
          if (callback) {
            callback(peer_id, data);
          }
          break;
        case COMMAND_GET_STATE:
          if (!data.length) {
            data = null;
          }
          state = this['get_state'](data);
          if (state) {
            this._make_response(peer_id, transaction_id, state);
          }
          break;
        case COMMAND_GET_PROOF:
          ref$ = parse_get_proof_request(data), state_version = ref$[0], node_id = ref$[1];
          this._make_response(peer_id, transaction_id, this._dht['get_state_proof'](state_version, node_id));
          break;
        case COMMAND_GET_VALUE:
          value = this._values.get(data);
          this._make_response(peer_id, transaction_id, value || null_array);
          break;
        case COMMAND_PUT_VALUE:
          ref$ = parse_put_value_request(data), key = ref$[0], payload = ref$[1];
          if (this['verify_value'](key, payload)) {
            this._values.add(key, payload);
          } else {
            this._peer_error(peer_id);
          }
        }
      }
      /**
       * @param {!Uint8Array} node_id
       *
       * @return {!Promise} Resolves with `!Array<!Uint8Array>`
       */,
      'lookup': function(node_id){
        if (this._destroyed) {
          return Promise.reject();
        }
        return this._handle_lookup(node_id, this._dht['start_lookup'](node_id));
      }
      /**
       * @param {!Uint8Array}					node_id
       * @param {!Array<!Array<!Uint8Array>>}	nodes_to_connect_to
       *
       * @return {!Promise}
       */,
      _handle_lookup: function(node_id, nodes_to_connect_to){
        var this$ = this;
        if (this._destroyed) {
          return Promise.reject();
        }
        return new Promise(function(resolve, reject){
          var found_nodes, nodes_for_next_round, pending, i$, ref$, len$;
          if (!nodes_to_connect_to.length) {
            found_nodes = this$._dht['finish_lookup'](node_id);
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
              this$._handle_lookup(node_id, nodes_for_next_round).then(resolve);
            }
          }
          for (i$ = 0, len$ = (ref$ = nodes_to_connect_to).length; i$ < len$; ++i$) {
            (fn$.call(this$, ref$[i$]));
          }
          function fn$(arg$){
            var target_node_id, parent_node_id, parent_state_version, this$ = this;
            target_node_id = arg$[0], parent_node_id = arg$[1], parent_state_version = arg$[2];
            this._make_request(parent_node_id, COMMAND_GET_PROOF, compose_get_proof_request(parent_state_version, target_node_id), this._timeouts['GET_PROOF_REQUEST_TIMEOUT']).then(function(proof){
              var target_node_state_version;
              target_node_state_version = this$._dht['check_state_proof'](parent_state_version, proof, target_node_id);
              if (target_node_state_version) {
                this$._connect_to(target_node_id, parent_node_id).then(function(){
                  return this$._make_request(target_node_id, COMMAND_GET_STATE, target_node_state_version, this$._timeouts['GET_STATE_REQUEST_TIMEOUT']).then(parse_state).then(function(arg$){
                    var state_version, proof, peers, proof_check_result;
                    state_version = arg$[0], proof = arg$[1], peers = arg$[2];
                    proof_check_result = this$._dht['check_state_proof'](state_version, proof, target_node_id);
                    if (are_arrays_equal(target_node_state_version, state_version) && proof_check_result && are_arrays_equal(proof_check_result, target_node_id)) {
                      nodes_for_next_round = nodes_for_next_round.concat(this$._dht['update_lookup'](node_id, target_node_id, target_node_state_version, peers));
                    } else {
                      this$._peer_error(target_node_id);
                    }
                    done();
                  })['catch'](function(error){
                    error_handler(error);
                    this._peer_warning(target_node_id);
                    done();
                  });
                });
              } else {
                this$._peer_error(parent_node_id);
                done();
              }
            })['catch'](function(error){
              error_handler(error);
              this._peer_warning(parent_node_id);
              done();
            });
          }
        });
      }
      /**
       * @parm {!Uint8Array} peer_id
       */,
      _peer_error: function(peer_id){
        this['fire']('peer_error', peer_id);
        this['del_peer'](peer_id);
      }
      /**
       * @parm {!Uint8Array} peer_id
       */,
      _peer_warning: function(peer_id){
        this['fire']('peer_warning', peer_id);
      }
      /**
       * @param {!Uint8Array}	peer_peer_id	Peer's peer ID
       * @param {!Uint8Array}	peer_id			Peer ID
       *
       * @return {!Promise}
       */,
      _connect_to: function(peer_peer_id, peer_id){
        return this['fire']('connect_to', peer_peer_id, peer_id);
      }
      /**
       * @param {Uint8Array=} state_version	Specific state version or latest if `null`
       *
       * @return {!Uint8Array}
       */,
      'get_state': function(state_version){
        var ref$, proof, peers;
        state_version == null && (state_version = null);
        if (this._destroyed) {
          return null_array;
        }
        ref$ = this._dht['get_state'](state_version), state_version = ref$[0], proof = ref$[1], peers = ref$[2];
        return compose_state(state_version, proof, peers);
      }
      /**
       * @return {!Array<!Uint8Array>}
       */,
      'get_peers': function(){
        if (this._destroyed) {
          return [];
        }
        return this._dht['get_state']()[2];
      }
      /**
       * @param {!Uint8Array}	peer_id	Id of a peer
       * @param {!Uint8Array}	state	Peer's state generated with `get_state()` method
       *
       * @return {boolean} `false` if proof is not valid, returning `true` only means there was not errors, but peer was not necessarily added to k-bucket
       *                   (use `has_peer()` method if confirmation of addition to k-bucket is needed)
       */,
      'set_peer': function(peer_id, state){
        var ref$, peer_state_version, proof, peer_peers, result;
        if (this._destroyed) {
          return false;
        }
        ref$ = parse_state(state), peer_state_version = ref$[0], proof = ref$[1], peer_peers = ref$[2];
        result = this._dht['set_peer'](peer_id, peer_state_version, proof, peer_peers);
        if (!result) {
          this._peer_error(peer_id);
        }
        return result;
      }
      /**
       * @param {!Uint8Array} node_id
       *
       * @return {boolean} `true` if node is our peer (stored in k-bucket)
       */,
      'has_peer': function(node_id){
        if (this._destroyed) {
          return false;
        }
        return this._dht['has_peer'](node_id);
      }
      /**
       * @param {!Uint8Array} peer_id Id of a peer
       */,
      'del_peer': function(peer_id){
        if (this._destroyed) {
          return;
        }
        this._dht['del_peer'](peer_id);
      }
      /**
       * @param {!Uint8Array} key
       *
       * @return {!Promise} Resolves with value on success
       */,
      'get_value': function(key){
        var value, this$ = this;
        if (this._destroyed) {
          return Promise.reject();
        }
        value = this._values.get(key);
        if (value && are_arrays_equal(blake2b_256(value), key)) {
          return Promise.resolve(value);
        }
        return this['lookup'](key).then(function(peers){
          return new Promise(function(resolve, reject){
            var pending, stop, found, i$, ref$, len$, peer_id;
            pending = peers.length;
            stop = false;
            found = value ? this$._verify_mutable_value(key, value) : null;
            if (!peers.length) {
              finish();
            }
            function done(){
              if (stop) {
                return;
              }
              pending--;
              if (!pending) {
                finish();
              }
            }
            function finish(){
              if (!found) {
                reject();
              } else {
                resolve(found[1]);
              }
            }
            for (i$ = 0, len$ = (ref$ = peers).length; i$ < len$; ++i$) {
              peer_id = ref$[i$];
              this$._make_request(peer_id, COMMAND_GET_VALUE, key, this$._timeouts['GET_VALUE_TIMEOUT']).then(fn$)['catch'](fn1$);
            }
            function fn$(data){
              var payload;
              if (stop) {
                return;
              }
              if (!data.length) {
                done();
                return;
              }
              if (are_arrays_equal(blake2b_256(data), key)) {
                stop = true;
                resolve(data);
                return;
              }
              payload = this$._verify_mutable_value(key, data);
              if (payload) {
                if (!found || found[0] < payload[0]) {
                  found = payload;
                }
              } else {
                this$._peer_error(peer_id);
              }
              done();
            }
            function fn1$(error){
              error_handler(error);
              this._peer_warning(peer_id);
              done();
            }
          });
        });
      }
      /**
       * @param {!Uint8Array} key
       * @param {!Uint8Array} data
       *
       * @return {Array} `[version, value]` if signature is correct or `null` otherwise
       */,
      _verify_mutable_value: function(key, data){
        var payload, signature;
        if (data.length < SIGNATURE_LENGTH + 5) {
          return null;
        }
        payload = data.subarray(0, data.length - SIGNATURE_LENGTH);
        signature = data.subarray(data.length - SIGNATURE_LENGTH);
        if (!verify_signature(signature, payload, key)) {
          return null;
        }
        return parse_mutable_value(payload);
      }
      /**
       * @param {!Uint8Array} value
       *
       * @return {!Array<!Uint8Array>} `[key, data]`, can be published to DHT with `put_value()` method
       */,
      'make_immutable_value': function(value){
        var key;
        key = blake2b_256(value);
        return [key, value];
      }
      /**
       * @param {!Uint8Array}	public_key	Ed25519 public key, will be used as key for data
       * @param {!Uint8Array}	private_key	Ed25519 private key
       * @param {number}		version		Up to 32-bit number
       * @param {!Uint8Array}	value
       *
       * @return {!Array<!Uint8Array>} `[key, data]`, can be published to DHT with `put_value()` method
       */,
      'make_mutable_value': function(public_key, private_key, version, value){
        var payload, signature, data;
        payload = compose_mutable_value(version, value);
        signature = create_signature(payload, public_key, private_key);
        data = concat_arrays([payload, signature]);
        return [public_key, data];
      }
      /**
       * @param {!Uint8Array} key
       * @param {!Uint8Array} data
       *
       * @return {Uint8Array} `value` if correct data and `null` otherwise
       */,
      'verify_value': function(key, data){
        var payload;
        if (are_arrays_equal(blake2b_256(data), key)) {
          return data;
        }
        payload = this._verify_mutable_value(key, data);
        if (payload) {
          return payload[1];
        } else {
          return null;
        }
      }
      /**
       * @param {!Uint8Array} key		As returned by `make_*_value()` methods
       * @param {!Uint8Array} data	As returned by `make_*_value()` methods
       *
       * @return {!Promise}
       */,
      'put_value': function(key, data){
        var this$ = this;
        if (this._destroyed) {
          return Promise.reject();
        }
        if (!this['verify_value'](key, data)) {
          return Promise.reject();
        }
        this._values.add(key, data);
        return this['lookup'](key).then(function(peers){
          var command_data, i$, len$, peer_id, results$ = [];
          if (!peers.length) {
            return;
          }
          command_data = compose_put_value_request(key, data);
          for (i$ = 0, len$ = peers.length; i$ < len$; ++i$) {
            peer_id = peers[i$];
            results$.push(this$._make_request(peer_id, COMMAND_PUT_VALUE, command_data, this$._timeouts['PUT_VALUE_TIMEOUT']));
          }
          return results$;
        });
      },
      'destroy': function(){
        if (this._destroyed) {
          return;
        }
        this._destroyed = true;
        this._timeouts_in_progress.forEach(clearTimeout);
        return clearInterval(this._state_update_interval);
      }
      /**
       * @param {!Uint8Array}	peer_id
       * @param {number}		command
       * @param {!Uint8Array}	data
       * @param {number}		request_timeout	In seconds
       *
       * @return {!Promise} Will resolve with data received from `peer_id`'s response or will reject on timeout
       */,
      _make_request: function(peer_id, command, data, request_timeout){
        var promise, this$ = this;
        promise = new Promise(function(resolve, reject){
          var transaction_id, timeout;
          transaction_id = this$._generate_transaction_id();
          this$._transactions_in_progress.set(transaction_id, function(peer_id, data){
            if (are_arrays_equal(peer_id, peer_id)) {
              clearTimeout(timeout);
              this$._timeouts_in_progress['delete'](timeout);
              this$._transactions_in_progress['delete'](transaction_id);
              resolve(data);
            }
          });
          timeout = timeoutSet(request_timeout, function(){
            this$._transactions_in_progress['delete'](transaction_id);
            this$._timeouts_in_progress['delete'](timeout);
            reject();
          });
          this$._timeouts_in_progress.add(timeout);
          this$._send(peer_id, command, compose_payload(transaction_id, data));
        });
        promise['catch'](error_handler);
        return promise;
      }
      /**
       * @param {!Uint8Array}	peer_id
       * @param {number}		transaction_id
       * @param {!Uint8Array}	data
       */,
      _make_response: function(peer_id, transaction_id, data){
        this._send(peer_id, COMMAND_RESPONSE, compose_payload(transaction_id, data));
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
       * @param {!Uint8Array} peer_id
       * @param {!Uint8Array} command
       * @param {!Uint8Array} payload
       */,
      _send: function(peer_id, command, payload){
        this['fire']('send', peer_id, command, payload);
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
