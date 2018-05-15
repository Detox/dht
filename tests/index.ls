/**
 * @package Detox DHT
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
detox-utils	= require('@detox/utils')
lib			= require('..')
test		= require('tape')

<-! lib.ready

ArrayMap		= detox-utils.ArrayMap
random_bytes	= detox-utils.random_bytes

test('Detox DHT', (t) !->
	t.plan(6)

	console.log 'Creating instances...'
	function DHT (id)
		instance	= lib.DHT(id, 20, 1000, 1000)
			.on('connect_to', (peer_peer_id) !->
				instance.set_peer(peer_peer_id, instances.get(peer_peer_id).get_state())
			)
			.on('send', (target_id, command, payload) !->
				instances.get(target_id).receive(id, command, payload)
			)

	instances				= ArrayMap()
	nodes					= []
	bootstrap_node_id		= random_bytes(32)
	bootstrap_node_instance	= DHT(bootstrap_node_id)
	instances.set(bootstrap_node_id, bootstrap_node_instance)
	for let _ from 0 til 100
		id			= random_bytes(32)
		instance	= DHT(id)
		nodes.push(id)
		instances.set(id, instance)
		bootstrap_node_instance.set_peer(id, instance.get_state())
		instance.set_peer(bootstrap_node_id, bootstrap_node_instance.get_state())

	console.log 'Warm-up...'

	node_a	= instances.get(nodes[index_a = Math.floor(nodes.length * Math.random())])
	node_b	= instances.get(nodes[index_b = Math.floor(nodes.length * Math.random())])
	node_c	= instances.get(nodes[index_c = Math.floor(nodes.length * Math.random())])

	data		= random_bytes(10)
	[key, data]	= node_a.make_immutable_value(data)
	node_a.put_value(key, data)

	!function destroy
		instances.forEach (instance) !->
			instance.destroy()

	node_a.get_value(key)
		.then (value) ->
			t.equal(value.join(','), data.join(','), 'getting immutable data on node a succeeded')
			node_b.get_value(key)
		.then (value) ->
			t.equal(value.join(','), data.join(','), 'getting immutable data on node b succeeded')
			node_c.get_value(key)
		.then (value) ->
			t.equal(value.join(','), data.join(','), 'getting immutable data on node c succeeded')
			node_a.lookup(random_bytes(32))
		.then (lookup_nodes) !->
			t.ok(lookup_nodes.length >= 2 && lookup_nodes.length <= 20, 'Found at most 20 nodes on random lookup, but not less than 2')
			t.ok(lookup_nodes[0] instanceof Uint8Array, 'Node has correct ID type')
			t.equal(lookup_nodes[0].length, 32, 'Node has correct ID length')
		.then !->
			destroy()
		.catch (e) !->
			if e
				console.error e
			destroy()
)
