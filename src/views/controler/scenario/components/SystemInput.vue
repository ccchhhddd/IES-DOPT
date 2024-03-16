<script setup lang="ts">
import { Handle, Position } from '@vue-flow/core'
import { NButton, NDrawer, NDrawerContent, NInput, NPopselect } from 'naive-ui'
import { inject, ref, type Ref } from 'vue';
import Func from './somefuncs'

const nodes = inject('sysNodes')

const props = defineProps({
	id: {
		type: String,
		required: true,
	}
})
const simArgs = inject('simArgs') as Ref<{
	start: boolean,
	nodes: Map<string, any>,
	adjacencyMatrix: Array<any>
}>
const show = ref(false)
const msg = ref({
	type: '阶跃输入',
	args: {
		K: '1',
		t: '0'
	}
})
if (simArgs.value.nodes.has(props.id)) {
	msg.value = simArgs.value.nodes.get(props.id)
}
simArgs.value.nodes.set(props.id, msg.value)
const value = ref('阶跃输入')
const options = [
	{
		label: '阶跃输入',
		value: '阶跃输入'
	},
	{
		label: '斜坡输入',
		value: '斜坡输入'
	},
	{
		label: '抛物线输入',
		value: '抛物线输入'
	}
]
function CallBack() {
	simArgs.value.nodes.delete(props.id)
	msg.value.type = value.value
	simArgs.value.nodes.set(props.id, msg.value)
}
</script>

<template>
	<NButton @dblclick="show = true" class="sys-input">
		<p><strong>系统输入</strong></p>
		<Handle
			id="a"
			type="source"
			:position="Position.Right"
			:is-valid-connection="(conn) => Func(conn, nodes)"
			:style="{
				backgroundColor: 'blue',
			}"
		/>
	</NButton>
	<n-drawer v-model:show="show" :width="502">
		<n-drawer-content title="输入参数设置" closable>
			<n-popselect v-model:value="value" :options="options" trigger="click" @click="CallBack">
	    		<n-button>{{ value || '弹出选择' }}</n-button>
	  		</n-popselect>
			<n-input v-model:value="msg.args.K" placeholder="1">
				<template #prefix>
					比例系数:
				</template>
			</n-input>
			<n-input v-model:value="msg.args.t" placeholder="1">
				<template #prefix>
					阶跃时间:
				</template>
			</n-input>
		</n-drawer-content>
	</n-drawer>
	<div>{{ props.id }}</div>
</template>
