<script setup lang="ts">
import { MarkerType, VueFlow, useVueFlow } from '@vue-flow/core'
import { MiniMap } from '@vue-flow/minimap'
import { Background } from '@vue-flow/background'
import { Controls } from '@vue-flow/controls'
import { markRaw, nextTick, provide, ref, watch } from 'vue'
import { NMessageProvider, NDropdown } from 'naive-ui'
import Sidebar from './SideBar.vue'
import Tf from './TransferFunction.vue'
import SumBlock from './SumBlock.vue'
import SimulatorBox from './SimulatorBox.vue'
import Plink from './ProportionalComponent.vue'
import Ilink from './IntegralComponent.vue'
import IDlink from './IdealDifferentialLink.vue'
import ADlink from './ActualDifferentiationProcess.vue'
import InPut from './SystemInput.vue'
import Scope from './ScopeComponent.vue'
import SumPoint from './SumPoint.vue'

// 组件类型登记
const nodeTypes = {
  sinput: markRaw(InPut),
  transferfunction: markRaw(Tf),
  sumblock: markRaw(SumBlock),
  plink: markRaw(Plink),
  integrator: markRaw(Ilink),
  idealdiff: markRaw(IDlink),
  actualdiff: markRaw(ADlink),
  soutput: markRaw(Scope),
  sum: markRaw(SumPoint),
}
// 仿真参数储存
const simArgs = ref({
  start: false,
  nodes: new Map(),
  adjacencyMatrix: []
})
// 仿真结果储存
const simResult = ref({
  done: false,
  data: []
})
// 主侧边栏显示
const show = ref(false)
// 组件交互依赖项
const {
  findNode,
  getEdges,
  getNodes,
  removeEdges,
  removeNodes,
  onConnect,
  addEdges,
  addNodes,
  onEdgeContextMenu,
  onNodeContextMenu,
  project,
  vueFlowRef
} = useVueFlow({
  nodes: [
  ]
})
// 右键菜单依赖项
const showDropdownRef = ref(false)
const xRef = ref(0)
const yRef = ref(0)
const options = [
  {
    label: '删除',
    key: '3'
  }
]
// 透传依赖
provide('sysEdges', getEdges)
provide('sysNodes', getNodes)
provide('show', show)
provide('simArgs', simArgs)
provide('simResult', simResult)
// 连接线设置
onConnect((params) => {
  const newpar = {
    source: params.source,
    target: params.target,
    sourceHandle: params.sourceHandle,
    targetHandle: params.targetHandle,
    style: {
      stroke: 'rgb(0,0,0)',
      strokeWidth: '4px'
    },
    markerEnd: MarkerType.Arrow,
  }
  addEdges(newpar)
})
const s = ref({
  name: '',
  type: ''
})
onEdgeContextMenu(({ edge }) => {
  s.value.name = edge.id
  s.value.type = 'edge'
  handleContextMenu()
})
onNodeContextMenu(({ node }) => {
  s.value.name = node.id
  s.value.type = 'node'
  handleContextMenu()
})
// 右键菜单交互
function handleSelect(key: string | number) {
  showDropdownRef.value = false
  if (key == '3') {
    if (s.value.type == 'edge') {
      removeEdges(s.value.name)
    } else if (s.value.type == 'node') {
      removeNodes(s.value.name)
      simArgs.value.nodes.delete(s.value.name)
    }
  }
}
function handleContextMenu() {
  showDropdownRef.value = false
  nextTick().then(() => {
    showDropdownRef.value = true
  })
}
function getMXY(e: MouseEvent) {
  e.preventDefault()
  xRef.value = e.clientX
  yRef.value = e.clientY
}
// 组件拖拽设置
let id = 0
function getId() {
  return `node_${id++}`
}
function onDragOver(event: any) {
  event.preventDefault()
  if (event.dataTransfer) {
    event.dataTransfer.dropEffect = 'move'
  }
}
function onDrop(event: any) {
  const type = event.dataTransfer?.getData('application/vueflow')
  const { left, top } = (vueFlowRef.value as any).getBoundingClientRect()
  const position = project({
    x: event.clientX - left,
    y: event.clientY - top,
  })

  const newNode = {
    id: getId(),
    type,
    position,
    label: `${type} node`,
  }

  addNodes([newNode])

  // align node position after drop, so it's centered to the mouse
  nextTick(() => {
    const node = findNode(newNode.id)
    if (node != undefined) {
      const stop = watch(
        () => node.dimensions,
        (dimensions) => {
          if (dimensions.width > 0 && dimensions.height > 0) {
            node.position = { x: node.position.x - node.dimensions.width / 2, y: node.position.y - node.dimensions.height / 2 }
            stop()
          }
        },
        { deep: true, flush: 'post' },
      )
    }
  })
  show.value = true
}
</script>

<template>
  <div class="dndflow" @drop="onDrop" @click.right="getMXY" @click="showDropdownRef = false">
    <n-message-provider>
      <VueFlow
        @dragover="onDragOver"
        :node-types="nodeTypes"
        :default-edge-options="{
          type: 'smoothstep',
        }"
      >
        <MiniMap />
        <Background pattern-color="#aaa" :gap="8" />
        <Controls />
      </VueFlow>
      <Sidebar />
      <SimulatorBox />
    </n-message-provider>
    <n-dropdown placement="bottom-start" trigger="manual" :x="xRef" :y="yRef" :options="options" :show="showDropdownRef"
    	    @select="handleSelect" />
  </div>
</template>
