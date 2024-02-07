<script setup lang="ts">
import { Handle, Position } from '@vue-flow/core'
import { NButton, NModal, useMessage, NScrollbar } from 'naive-ui'
import { h, inject, nextTick, ref, type Ref } from 'vue';
import Func from './somefuncs'
import * as echarts from 'echarts/core';
import {
	LineChart
} from 'echarts/charts';
import {
	TitleComponent,
	TooltipComponent,
	GridComponent,
	// 数据集组件
	DatasetComponent,
	// 内置数据转换器组件 (filter, sort)
	TransformComponent
} from 'echarts/components';
import { LabelLayout, UniversalTransition } from 'echarts/features';
import { CanvasRenderer } from 'echarts/renderers';

// 注册必须的组件
echarts.use([
	TitleComponent,
	TooltipComponent,
	GridComponent,
	DatasetComponent,
	TransformComponent,
	LineChart,
	LabelLayout,
	UniversalTransition,
	CanvasRenderer
]);

const nodes = inject('sysNodes')
const show = ref(false)

const simResult = inject('simResult') as Ref<{
	done: Boolean,
	data: any
}>

function postProcessing(ans:any) {
	let newans = []
	for (let key of Object.keys(ans)) {
		if (String(key) == props.id) {
			for (let son of Object.keys(ans[key])) {
				newans.push({
					name: String(son),
					type: 'line',
					data: ans[key][son]
				})
			}
		}
	} 
	return newans
}

const multiGraph = ref(false)

const msg = useMessage()
function Scope() {
	if (simResult.value.done) {
		let data = postProcessing(simResult.value.data.ans)
		console.log(data)
		if (multiGraph.value) {
			let graph = []
			for (let d of data) {
				graph.push(h(
					'div',
					{
						class: 'picture',
						ref: (el: any) => {
							nextTick(() => {
								let myChart = echarts.init(el)
								myChart.setOption({
									title: {
										text: '输出变化图(关于'.concat(d.name,')')
									},
									tooltip: {},
									xAxis: {
										data: simResult.value.data.x
									},
									yAxis: {},
									series: [d]
								});
							})
						},
					}
				), h('br'))
			}
			return h(
				NScrollbar,
				graph
			)
		} else {
			return h(
				'div',
				{
					class: 'picture',
					ref: (el: any) => {
						nextTick(() => {
							let myChart = echarts.init(el)
							myChart.setOption({
								title: {
									text: '输出变化图'
								},
								tooltip: {},
								xAxis: {
									data: simResult.value.data.x
								},
								yAxis: {},
								series: data
							});
						})
					},
				}
			)
		}
	} else {
		if (multiGraph.value) {
			msg.error("没有数据,无法分图!")
		}
		return h(
			'div',
			{
				class: "picture",
				ref: (el: any) => {
					nextTick(() => {
						let myChart = echarts.init(el)
						myChart.showLoading()
					})
				},
			}
		)
	}
}

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
simArgs.value.nodes.set(props.id, {
	type:  'output'
})
</script>

<template>
	<NButton @dblclick="show = true" class="sys-output">
		<p><strong>示波器</strong></p>
		<Handle id="b" 
			type="target" 
			:position="Position.Left"
			:is-valid-connection="(conn) => Func(conn, nodes)"
			:style="{
				backgroundColor: 'red'
			}"
		/>
	</NButton>
	<n-modal
	    v-model:show="show"
	    :mask-closable="false"
	    preset="dialog"
	    title="示波器"
	    content="你确认"
		style="width: 1050px;"
	>
		<Scope/>
		<n-button @click="multiGraph = false">单图显示</n-button>
		<n-button @click="multiGraph = true">分图显示</n-button>
	</n-modal>
	<div>{{ props.id }}</div>
</template>