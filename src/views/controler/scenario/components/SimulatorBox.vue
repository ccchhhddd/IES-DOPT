<script setup lang="ts">
import { NButton } from 'naive-ui'
import { inject, ref, type Ref } from 'vue';
import axios from 'axios';

const nodes = inject('sysNodes') as any
const edges = inject('sysEdges') as any
const simArgs = inject('simArgs') as Ref<{ nodes: Map<string, any>, adjacencyMatrix: Array<any> }>

function matchIdNum(id:string, arr:any) {
	for (let a of arr) {
		if (id == a.nid) {
			return a.nnum
		}
	}
}
function isSum(id:string, arr:any) {
	for (let a of arr) {
		if (id == a.id) {
			if (a.type == 'sumblock' || a.type == 'sum') {
				return true
			}
		}
	}
	return false
}
const testid = ref('')
function getAdjacencyMatrix() {
	testid.value = nodes.value[0].id
	const ids = nodes.value.map((x: any) => {
		let s = undefined
		let t = undefined
		if (x.handleBounds.source != undefined) {
			s = x.handleBounds.source.map((x: any) => {
				x.id
			})
		}
		if (x.handleBounds.target != undefined) {
			t = x.handleBounds.target.map((x: any) => {
				x.id
			})
		}
		return {
			id: x.id,
			type: x.type,
			source: s,
			target: t
		}
	})
	const lines = edges.value.map((x: any) => {
		return {
			source: x.source,
			target: x.target,
			targetHandle: x.targetHandle
		}
	})
	var ajmatrix = []
	var num = 1
	var lens = ids.length
	for (let id of ids) {
		ajmatrix.push({
			nid: id.id,
			nnum: num,
			nnodes: Array.from({ length: lens }).map(() => 0)
		})
		num++
	}
	for (let line of lines) {
		let sid = matchIdNum(line.source, ajmatrix)
		let tid = matchIdNum(line.target, ajmatrix)
		if (isSum(line.target, nodes.value)) {
			let syms = simArgs.value.nodes.get(line.target).symbol
			switch (line.targetHandle) {
				case 'b':
					if (syms[1] == '+') {
						ajmatrix[sid - 1].nnodes[tid - 1] = 1
					} else {
						ajmatrix[sid - 1].nnodes[tid - 1] = -1
					}
					break;
				case 'c':
					if (syms[2] == '+') {
						ajmatrix[sid - 1].nnodes[tid - 1] = 1
					} else {
						ajmatrix[sid - 1].nnodes[tid - 1] = -1
					}
					break;
				case 'd':
					if (syms[3] == '+') {
						ajmatrix[sid - 1].nnodes[tid - 1] = 1
					} else {
						ajmatrix[sid - 1].nnodes[tid - 1] = -1
					}
					break;
				case 'e':
					if (syms[4] == '+') {
						ajmatrix[sid - 1].nnodes[tid - 1] = 1
					} else {
						ajmatrix[sid - 1].nnodes[tid - 1] = -1
					}
					break;
				case 'f':
					if (syms[5] == '+') {
						ajmatrix[sid - 1].nnodes[tid - 1] = 1
					} else {
						ajmatrix[sid - 1].nnodes[tid - 1] = -1
					}
					break;
			}
		} else {
			ajmatrix[sid - 1].nnodes[tid - 1] = 1
		}
	}
	simArgs.value.adjacencyMatrix = ajmatrix
}

const simResult = inject('simResult') as Ref<{
	done: Boolean,
	data: any
}>

function sendMsg() {
	let request = axios.create({
		timeout: 5000
	})
	let config = {
		headers: { 'Content-Type': "multipart/json, charset=UTF-8" }
	}
	let jsonobj = {}
	simArgs.value.nodes.forEach((v, k) => {
		jsonobj[k] = v
	})
	request.post('/jumulink', {
		nodes: jsonobj,
		map: simArgs.value.adjacencyMatrix
	}, config)
		.then((response: { data: any; }) => {
			simResult.value.done = true
			simResult.value.data = response.data
			console.log(response.data);
		})
		.catch((error: any) => {
			console.log(error);
		});
}

function simulationStart() {
	simResult.value.done = false;
	getAdjacencyMatrix()
	sendMsg()
}
</script>

<template>
	<NButton @click="simulationStart">按下以开始仿真!</NButton>
</template>
