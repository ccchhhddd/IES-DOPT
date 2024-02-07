<script setup lang="ts">
import { Handle, Position } from '@vue-flow/core'
import { NButton, NDrawer, NDrawerContent, NInput } from 'naive-ui'
import { inject, ref, type Ref } from 'vue';
import Func from './somefuncs'

const props = defineProps({
	id: {
		type: String,
		required: true,
	}
})
const nodes = inject('sysNodes') as any
const simArgs = inject('simArgs') as Ref<{
	start: boolean,
	nodes: Map<string, any>,
	adjacencyMatrix: Array<any>
}>
const show = ref(false)
const msg = ref({
	type: 'I',
	Ti: "1"
})
simArgs.value.nodes.set(props.id, msg.value)
</script>

<template>
	<NButton @dblclick="show = true" class="int-link">
		<p><strong>I</strong></p>
		<Handle id="a" 
			type="source" 
			:position="Position.Right" 
			:is-valid-connection="(conn) => Func(conn, nodes)"
			:style="{
				backgroundColor: 'blue'
			}"
		/>
		<Handle id="b" 
			type="target" 
			:position="Position.Left"
			:is-valid-connection="(conn) => Func(conn, nodes)"
			:style="{
				backgroundColor: 'red'
			}"
		/>
	</NButton>
	<n-drawer v-model:show="show" :width="502">
		<n-drawer-content title="基本传函参数设置" closable>
			<n-input v-model:value="msg.Ti" placeholder="1">
				<template #prefix>
					积分时间常数:
				</template>
			</n-input>
		</n-drawer-content>
	</n-drawer>
	<div>{{ props.id }}</div>
</template>