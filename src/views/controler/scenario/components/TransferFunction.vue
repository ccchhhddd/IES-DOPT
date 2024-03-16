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
const simArgs = inject('simArgs') as Ref<{
  start: boolean;
  nodes: Map<string, any>;
  adjacencyMatrix: Array<any>;
}>;
const nodes = inject('sysNodes');
const show = ref(false);
const msg = ref({
  type: 'TransFunction',
  num: '[0]',
  den: '[1]'
});
if (simArgs.value.nodes.has(props.id)) {
  msg.value = simArgs.value.nodes.get(props.id);
} else {
  simArgs.value.nodes.set(props.id, msg.value);
}
</script>

<template>
  <NButton class="transfer-function" @dblclick="show = true">
    <p><strong>G</strong></p>
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
      <n-input v-model:value="msg.num" placeholder="[0]">
        <template #prefix>分子多项式系数:</template>
      </n-input>
      <n-input v-model:value="msg.den" placeholder="[1]">
        <template #prefix>分母多项式系数:</template>
      </n-input>
    </n-drawer-content>
  </n-drawer>
  <div>{{ props.id }}</div>
</template>
