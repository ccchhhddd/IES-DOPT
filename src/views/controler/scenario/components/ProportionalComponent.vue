<script setup lang="ts">
import { inject, ref, type Ref } from 'vue';
import { NButton, NDrawer, NDrawerContent, NInput } from 'naive-ui';
import { Handle, Position } from '@vue-flow/core';
import Func from './somefuncs';

const props = defineProps({
  id: {
    type: String,
    required: true
  }
});
const nodes = inject('sysNodes') as any;
const simArgs = inject('simArgs') as Ref<{
  start: boolean;
  nodes: Map<string, any>;
  adjacencyMatrix: Array<any>;
}>;
const show = ref(false);
const msg = ref({
  type: 'P',
  Kp: '1'
});
if (simArgs.value.nodes.has(props.id)) {
  msg.value = simArgs.value.nodes.get(props.id);
} else {
  simArgs.value.nodes.set(props.id, msg.value);
}
</script>

<template>
  <NButton class="p-link" @dblclick="show = true">
    <svg xmlns="http://www.w3.org/2000/svg" version="1.1">
      <polygon
        points="2,25 2,125 102,75"
        style="stroke: rgb(23, 193, 105); stroke-width: 4px; fill: rgb(255, 255, 255)"
      />
      <text x="35" y="85">P</text>
    </svg>
    <Handle
      id="a"
      type="source"
      :position="Position.Right"
      :is-valid-connection="conn => Func(conn, nodes)"
      :style="{
        backgroundColor: 'blue'
      }"
    />
    <Handle
      id="b"
      type="target"
      :position="Position.Left"
      :is-valid-connection="conn => Func(conn, nodes)"
      :style="{
        backgroundColor: 'red'
      }"
    />
  </NButton>
  <n-drawer v-model:show="show" :width="502">
    <n-drawer-content title="基本传函参数设置" closable>
      <n-input v-model:value="msg.Kp" placeholder="1">
        <template #prefix>比例系数:</template>
      </n-input>
    </n-drawer-content>
  </n-drawer>
  <div>{{ props.id }}</div>
</template>
