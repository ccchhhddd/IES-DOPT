<script setup lang="ts">
import { markRaw, nextTick, provide, ref, watch } from 'vue';
import { NMessageProvider, NDropdown } from 'naive-ui';
import { MarkerType, VueFlow, useVueFlow, Panel } from '@vue-flow/core';
import { MiniMap } from '@vue-flow/minimap';
import { Background } from '@vue-flow/background';
import { Controls } from '@vue-flow/controls';
import Tf from './TransferFunction.vue';
import SumBlock from './SumBlock.vue';
import SimulatorBox from './SimulatorBox.vue';
import Plink from './ProportionalComponent.vue';
import Ilink from './IntegralComponent.vue';
import IDlink from './IdealDifferentialLink.vue';
import ADlink from './ActualDifferentiationProcess.vue';
import InPut from './SystemInput.vue';
import Scope from './ScopeComponent.vue';
import SumPoint from './SumPoint.vue';

function onDragStart(event: any, nodeType: any) {
  if (event.dataTransfer) {
    event.dataTransfer.setData('application/vueflow', nodeType);
    event.dataTransfer.effectAllowed = 'move';
  }
}
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
  sum: markRaw(SumPoint)
};
// 仿真参数储存
const simArgs = ref({
  start: false,
  nodes: new Map(),
  adjacencyMatrix: []
});
// 仿真结果储存
const simResult = ref({
  done: false,
  data: []
});
// 主侧边栏显示
const show = ref(false);
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
  vueFlowRef,
  toObject,
  fromObject
} = useVueFlow({
  nodes: []
});
// 右键菜单依赖项
const showDropdownRef = ref(false);
const xRef = ref(0);
const yRef = ref(0);
const options = [
  {
    label: '删除',
    key: '3'
  }
];
// 透传依赖
provide('sysEdges', getEdges);
provide('sysNodes', getNodes);
provide('show', show);
provide('simArgs', simArgs);
provide('simResult', simResult);
// 连接线设置
onConnect(params => {
  const newpar = {
    source: params.source,
    target: params.target,
    sourceHandle: params.sourceHandle,
    targetHandle: params.targetHandle,
    style: {
      stroke: 'rgb(0,0,0)',
      strokeWidth: '4px'
    },
    markerEnd: MarkerType.Arrow
  };
  addEdges(newpar);
});
const s = ref({
  name: '',
  type: ''
});
onEdgeContextMenu(({ edge }) => {
  s.value.name = edge.id;
  s.value.type = 'edge';
  handleContextMenu();
});
onNodeContextMenu(({ node }) => {
  s.value.name = node.id;
  s.value.type = 'node';
  handleContextMenu();
});
// 右键菜单交互
function handleSelect(key: string | number) {
  showDropdownRef.value = false;
  if (key == '3') {
    if (s.value.type == 'edge') {
      removeEdges(s.value.name);
    } else if (s.value.type == 'node') {
      removeNodes(s.value.name);
      simArgs.value.nodes.delete(s.value.name);
    }
  }
}
function handleContextMenu() {
  showDropdownRef.value = false;
  nextTick().then(() => {
    showDropdownRef.value = true;
  });
}
function getMXY(e: MouseEvent) {
  e.preventDefault();
  xRef.value = e.clientX;
  yRef.value = e.clientY;
}
// 组件拖拽设置
let id = 0;
function getId() {
  return `node_${id++}`;
}
function onDragOver(event: any) {
  event.preventDefault();
  if (event.dataTransfer) {
    event.dataTransfer.dropEffect = 'move';
  }
}
function onDrop(event: any) {
  const type = event.dataTransfer?.getData('application/vueflow');
  const { left, top } = (vueFlowRef.value as any).getBoundingClientRect();
  const position = project({
    x: event.clientX - left,
    y: event.clientY - top
  });

  const newNode = {
    id: getId(),
    type,
    position,
    label: `${type} node`
  };

  addNodes([newNode]);

  // align node position after drop, so it's centered to the mouse
  nextTick(() => {
    const node = findNode(newNode.id);
    if (node != undefined) {
      const stop = watch(
        () => node.dimensions,
        dimensions => {
          if (dimensions.width > 0 && dimensions.height > 0) {
            node.position = {
              x: node.position.x - node.dimensions.width / 2,
              y: node.position.y - node.dimensions.height / 2
            };
            stop();
          }
        },
        { deep: true, flush: 'post' }
      );
    }
  });
  show.value = true;
}
function onSave() {
  const blob = new Blob([JSON.stringify(toObject())], { type: 'text/plain;charset=utf-8' });
  const a = document.createElement('a');
  a.setAttribute('download', 'topology.json');
  a.href = URL.createObjectURL(blob);
  a.click();
  URL.revokeObjectURL(a.href);
  document.body.removeChild(a);
}
function onRestore(data) {
  const reader = new FileReader();
  reader.readAsText(data.fileList[0].file);
  reader.onload = res => {
    if (res) {
      const flow = JSON.parse(res.target.result);
      fromObject(flow);
    }
  };
}
</script>

<template>
  <div class="dndflow" @drop="onDrop" @click.right="getMXY" @click="showDropdownRef = false">
    <n-message-provider>
      <VueFlow
        :node-types="nodeTypes"
        :default-edge-options="{
          type: 'smoothstep'
        }"
        @dragover="onDragOver"
      >
        <MiniMap />
        <Background pattern-color="#aaa" :gap="8" style="background-color: white" />
        <Controls />
        <Panel>
          <n-button-group style="margin-top: 6px; margin-left: 6px">
            <n-upload :default-upload="false" :show-file-list="false" @change="onRestore">
              <n-button secondary strong>导入</n-button>
            </n-upload>
            <n-button secondary strong @click="onSave">导出</n-button>
          </n-button-group>
        </Panel>
      </VueFlow>
      <div
        style="display: flex; justify-content: center; align-items: center; flex-direction: column; margin-left: 5px"
      >
        <!-- <Sidebar /> -->
        <div style="background-color: white; width: 100%; height: 15px" />
        <div
          class="description"
          style="
            background-color: white;
            width: 100%;
            display: flex;
            justify-content: center;
            align-items: center;
            font-size: 15px;
          "
        >
          <strong>拖拽组件以放置</strong>
        </div>
        <n-scrollbar style="padding-right: 30px; background-color: white; padding-top: 15px; padding-bottom: 15px">
          <n-grid :cols="2" :y-gap="20" style="width: 300px; justify-items: center; align-items: center">
            <n-grid-item>
              <div
                class="sys-input"
                :draggable="true"
                style="display: flex; justify-content: center; align-items: center"
                @dragstart="onDragStart($event, 'sinput')"
              >
                <p><strong>系统输入</strong></p>
              </div>
              <div style="text-align: center">系统输入</div>
            </n-grid-item>
            <n-grid-item>
              <div
                class="transfer-function"
                style="display: flex; justify-content: center; align-items: center"
                :draggable="true"
                @dragstart="onDragStart($event, 'transferfunction')"
              >
                <p><strong>G</strong></p>
              </div>
              <div style="text-align: center">普通传函</div>
            </n-grid-item>
            <n-grid-item>
              <div
                class="sum-point"
                :draggable="true"
                style="display: flex; justify-content: center; align-items: center"
                @dragstart="onDragStart($event, 'sum')"
              >
                <svg xmlns="http://www.w3.org/2000/svg" version="1.1">
                  <circle cx="48" cy="75" r="46" stroke="black" stroke-width="4" fill="rgb(255, 255, 255)" />
                  <line x1="16" y1="43" x2="80" y2="107" style="stroke: rgb(9, 9, 9); stroke-width: 4" />
                  <line x1="80" y1="43" x2="16" y2="107" style="stroke: rgb(5, 5, 5); stroke-width: 4" />
                  <text x="10" y="85" class="sum-point-symbol">+</text>
                </svg>
              </div>
              <div style="text-align: center">和点</div>
            </n-grid-item>
            <n-grid-item>
              <div
                class="sum-block"
                :draggable="true"
                style="display: flex; justify-content: center; align-items: center"
                @dragstart="onDragStart($event, 'sumblock')"
              >
                <div style="display: flex; flex-direction: column">
                  <span class="sum-block-span" style="height: 21px">+</span>
                  <span class="sum-block-span" style="height: 21px">+</span>
                  <span class="sum-block-span" style="height: 21px">+</span>
                </div>
              </div>
              <div style="text-align: center">和块</div>
            </n-grid-item>
            <n-grid-item>
              <div
                class="p-link"
                :draggable="true"
                style="display: flex; justify-content: center; align-items: center"
                @dragstart="onDragStart($event, 'plink')"
              >
                <svg xmlns="http://www.w3.org/2000/svg" version="1.1">
                  <polygon
                    points="2,25 2,125 102,75"
                    style="stroke: rgb(23, 193, 105); stroke-width: 4px; fill: rgb(255, 255, 255)"
                  />
                  <text x="35" y="85">P</text>
                </svg>
              </div>
              <div style="text-align: center">比例环节</div>
            </n-grid-item>
            <n-grid-item>
              <div
                class="int-link"
                :draggable="true"
                style="display: flex; justify-content: center; align-items: center"
                @dragstart="onDragStart($event, 'integrator')"
              >
                <p><strong>I</strong></p>
              </div>
              <div style="text-align: center">积分环节</div>
            </n-grid-item>
            <n-grid-item>
              <div
                class="diff-link"
                :draggable="true"
                style="display: flex; justify-content: center; align-items: center"
                @dragstart="onDragStart($event, 'idealdiff')"
              >
                <p><strong>D</strong></p>
              </div>
              <div style="text-align: center">理想微分环节</div>
            </n-grid-item>
            <n-grid-item>
              <div
                class="diff-link"
                :draggable="true"
                style="display: flex; justify-content: center; align-items: center"
                @dragstart="onDragStart($event, 'actualdiff')"
              >
                <span style="height: 70px; position: relative; left: 35px"><strong>D</strong></span>
                <br />
                <p style="font-size: 10px; position: relative; height: 10px; top: 27px; left: -10px">
                  <strong>实际微分环节</strong>
                </p>
              </div>
              <div style="text-align: center">实际微分环节</div>
            </n-grid-item>
            <n-grid-item>
              <div
                class="sys-output"
                :draggable="true"
                style="display: flex; justify-content: center; align-items: center"
                @dragstart="onDragStart($event, 'soutput')"
              >
                <p><strong>示波器</strong></p>
              </div>
              <div style="text-align: center">示波器</div>
            </n-grid-item>
          </n-grid>
        </n-scrollbar>
        <SimulatorBox style="width: 95%; height: 40px; margin-top: 10px" />
      </div>
    </n-message-provider>
    <n-dropdown
      placement="bottom-start"
      trigger="manual"
      :x="xRef"
      :y="yRef"
      :options="options"
      :show="showDropdownRef"
      @select="handleSelect"
    />
  </div>
</template>
