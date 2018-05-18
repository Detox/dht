# Detox DHT [![Travis CI](https://img.shields.io/travis/Detox/dht/next.svg?label=Travis%20CI)](https://travis-ci.org/Detox/dht)
DHT implementation for Detox project.

DHT with simple API that allows to make lookups and put immutable/mutable values into DHT.
It is built on top of [ES-DHT](https://github.com/nazar-pc/es-dht) framework and uses `@detox/crypto` for cryptographic needs.
Still agnostic to transport layer.

## How to install
```
npm install @detox/dht
```

## How to use
Node.js:
```javascript
var detox_dht = require('@detox/dht')

detox_dht.ready(function () {
    // Do stuff
});
```
Browser:
```javascript
requirejs(['@detox/dht'], function (detox_dht) {
    detox_dht.ready(function () {
        // Do stuff
    });
})
```

## API
### detox_dht.ready(callback)
* `callback` - Callback function that is called when library is ready for use

### detox_dht.DHT(dht_public_key : Uint8Array, bucket_size : number, state_history_size : number, values_cache_size : number, fraction_of_nodes_from_same_peer = 0.2 : number, timeouts = {} : Object) : detox_dht.DHT
Constructor for DHT object.

* `dht_public_key` - ed25519 that corresponds to temporary user identity in DHT network
* `bucket_size` - size of a bucket from Kademlia design
* `state_history_size` - how many versions of local history will be kept
* `values_cache_size` - how many values will be kept in cache
* `fraction_of_nodes_from_same_peer` - max fraction of nodes originated from single peer allowed on lookup start
* `timeouts` - various timeouts and intervals used internally

Following timeouts keys are supported, refer to source code for default values:
* `GET_PROOF_REQUEST_TIMEOUT`
* `GET_STATE_REQUEST_TIMEOUT`
* `GET_VALUE_TIMEOUT`
* `PUT_VALUE_TIMEOUT`
* `STATE_UPDATE_INTERVAL`

### detox_dht.DHT.receive(peer_id : Uint8Array, command : number, payload : Uint8Array)
Method needs to be called when DHT `command` is received from `peer_id` with `payload`.

### detox_dht.DHT.lookup(node_id : Uint8Array) : Promise
Promise resolves with `Uint8Array[]`, array will contain either `node_id` or IDs of nodes that are closest to it.

### detox_dht.DHT.get_state() : Uint8Array
Used during on connection to new peer, will return latest state that can be consumed by `set_peer()` method.

### detox_dht.DHT.get_peers() : Uint8Array[]
Returns IDs of all peers.

### detox_dht.DHT.set_peer(peer_id : Uint8Array, state : Uint8Array) : boolean
Add or update peer, usually only used explicitly on connection to new peer.

Returns `false` if state proof is not valid, returning `true` only means there was not errors, but peer was not necessarily added to k-bucket (use `has_peer()` method if confirmation of addition to k-bucket is needed).

### detox_dht.DHT.has_peer(node_id : Uint8Array) : boolean
Returns `true` if `node_id` is our peer (stored in k-bucket).

### detox_dht.DHT.del_peer(peer_id : Uint8Array)
Delete peer `peer_id`, for instance, when peer is disconnected.

### detox_dht.DHT.get_value(value : Uint8Array) : Promise
Resolves with value on success.

### detox_dht.DHT.make_immutable_value(key : Uint8Array) : Uint8Array[]
Returns `[key, data]`, can be placed into DHT with `put_value()` method or `null` if value is too big to be stored in DHT.

### detox_dht.DHT.make_mutable_value(public_key : Uint8Array, private_key : Uint8Array, version : number, value : Uint8Array) : Uint8Array[]
* `public_key` - ed25519 public key, will be used as key for mutable data
* `private_key` - corresponding ed25519 private key
* `version` - up to 32-bit version, increasing this value allows to update older value
* `value` - value to be placed into DHT

Returns `[key, data]`, can be placed into DHT with `put_value()` method or `null` if value is too big to be stored in DHT.

### detox_dht.DHT.verify_value(key : Uint8Array, data : Uint8Array) : Uint8Array
Allows to check whether `key` and `data` as returned by `make_*_value()` methods are valid.

Returns `value` if correct data and `null` otherwise.

### detox_dht.DHT.put_value(key : Uint8Array, data : Uint8Array) : Promise
Put `key` and `data` as returned by `make_*_value()` into DHT.

### detox_dht.DHT.destroy()
Destroy instance.

### detox_dht.DHT.on(event: string, callback: Function) : detox_dht.DHT
Register event handler.

### detox_dht.DHT.once(event: string, callback: Function) : detox_dht.DHT
Register one-time event handler (just `on()` + `off()` under the hood).

### detox_dht.DHT.off(event: string[, callback: Function]) : detox_dht.DHT
Unregister event handler.

### Event: peer_error
Payload consists of single `Uint8Array` argument `peer_id`.

Event is fired to notify higher level about peer error, error is a strong indication of malicious node, communication must be stopped immediately.

### Event: peer_warning
Payload consists of single `Uint8Array` argument `peer_id`.

Event is fired to notify higher level about peer warning, warning is a potential indication of malicious node, but threshold must be implemented on higher level.

### Event: connect_to
Payload consists of two `Uint8Array` arguments: `peer_peer_id` and `peer_id`.

Event is fired when connection needs to be established to `peer_id`'s peer `peer_peer_id`.

### Event: send
Payload consists of three arguments: `peer_id` (`Uint8Array`), `command` (`number`) and `payload` (`Uint8Array`).

Event is fired when DHT `command` needs to be sent to `peer_id` with `payload`.

### detox_dht.MAX_VALUE_LENGTH : number
Constant that defines max size of a value that can be stored in DHT.

## Contribution
Feel free to create issues and send pull requests (for big changes create an issue first and link it from the PR), they are highly appreciated!

When reading LiveScript code make sure to configure 1 tab to be 4 spaces (GitHub uses 8 by default), otherwise code might be hard to read.

## License
Free Public License 1.0.0 / Zero Clause BSD License

https://opensource.org/licenses/FPL-1.0.0

https://tldrlegal.com/license/bsd-0-clause-license
