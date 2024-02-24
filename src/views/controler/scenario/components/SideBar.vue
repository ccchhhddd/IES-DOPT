<script setup lang="ts">
import { NButton, NDrawer, NDrawerContent } from 'naive-ui'
import { inject, type Ref } from 'vue';
const show = inject('show') as Ref
function onDragStart(event:any, nodeType:any) {
	if (event.dataTransfer) {
		event.dataTransfer.setData('application/vueflow', nodeType)
		event.dataTransfer.effectAllowed = 'move'
		show.value = false
	}
}
</script>

<template>
	<NButton @click="show = true">按下按钮放置组件!</NButton>
	<n-drawer v-model:show="show" :width="502">
		<n-drawer-content title="组件列表" closable>
		<aside>
			<div class="description">拖拽组件以放置</div>
			<div style="display: flex; flex-direction: row; flex-wrap: wrap; justify-content: center; max-width: 90%; margin: auto; gap: 3px">
				<div class="menu" :draggable="true" @dragstart="onDragStart($event, 'sinput')">
					Input
					<p>系统输入</p>
				</div>
				<div class="menu" :draggable="true" @dragstart="onDragStart($event, 'transferfunction')">
					TransferFunction
					<p>普通传函</p>
				</div>
				<div class="menu" :draggable="true" @dragstart="onDragStart($event, 'sum')">
					SumPoint
					<p>和点</p>
				</div>
				<div class="menu" :draggable="true" @dragstart="onDragStart($event, 'sumblock')">
					SumBlock
					<p>和块</p>
				</div>
				<div class="menu" :draggable="true" @dragstart="onDragStart($event, 'plink')">
					<strong>P</strong>
					<p>比例环节</p>
				</div>
				<div class="menu" :draggable="true" @dragstart="onDragStart($event, 'integrator')">
					<strong>I</strong>
					<p>积分环节</p>
				</div>
				<div class="menu" :draggable="true" @dragstart="onDragStart($event, 'idealdiff')">
					D
					<p>理想微分环节</p>
				</div>
				<div class="menu" :draggable="true" @dragstart="onDragStart($event, 'actualdiff')">
					D
				<p>实际微分环节</p>
				</div>
				<div class="menu" :draggable="true" @dragstart="onDragStart($event, 'soutput')">
					<p>示波器</p>
				</div>
			</div>
		</aside>
		</n-drawer-content>
	</n-drawer>
</template>
