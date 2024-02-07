<script setup lang="ts">
import { ref, nextTick } from 'vue'
import { useMessage } from 'naive-ui'
import { NDropdown } from 'naive-ui'


const props = defineProps({
	options: Array,
	id: String
})

const message = useMessage()

const showDropdownRef = ref(false)
const xRef = ref(0)
const yRef = ref(0)	
		
function handleSelect(key: string | number) {
	showDropdownRef.value = false
	if (key == '3') {
		let d = document.getElementById(props.id as string)
		d?.remove()
	}
	message.info(String(key))
}
	
function handleContextMenu(e: MouseEvent) {
	e.preventDefault()
	showDropdownRef.value = false
	nextTick().then(() => {
		showDropdownRef.value = true
		xRef.value = e.clientX
		yRef.value = e.clientY
	})
}

function onClickoutside() {
	message.info('clickoutside')
	showDropdownRef.value = false
}
			
</script>

<template>
	<div :id="props.id" style="width: 200px; height: 200px;" @contextmenu="handleContextMenu">
		<slot></slot>
	</div>
	<n-dropdown placement="bottom-start" trigger="manual" :x="xRef" :y="yRef" :options="(props.options as any)" :show="showDropdownRef"
		:on-clickoutside="onClickoutside" @select="handleSelect" />
</template>