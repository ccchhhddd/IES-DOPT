<script setup lang="ts">
import { h, inject, reactive, ref, type Ref } from 'vue';
import { NDrawer, NDrawerContent, NInput, NButton, useMessage } from 'naive-ui';
import { Handle, Position } from '@vue-flow/core';
import Func from './somefuncs';

const show = ref(false);
const nodes = inject('sysNodes') as any;
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
const opts = reactive({
  label: 'SumBlock',
  symbol: '[+++]'
});
if (simArgs.value.nodes.has(props.id)) {
  opts.symbol = simArgs.value.nodes.get(props.id).symbol;
} else {
  simArgs.value.nodes.set(props.id, opts.symbol);
}
const c = h(Handle, {
  id: 'a',
  type: 'source',
  position: Position.Right,
  isValidConnection: conn => Func(conn, nodes.value),
  style: {
    top: '100px',
    backgroundColor: 'blue'
  }
});

const ids = [
  {
    id: 'b',
    num: 1
  },
  {
    id: 'c',
    num: 2
  },
  {
    id: 'd',
    num: 3
  },
  {
    id: 'e',
    num: 4
  },
  {
    id: 'f',
    num: 5
  }
];

const msg = useMessage();

function SumNode() {
  if (show.value) {
    return h('div', c);
  }

  simArgs.value.nodes.delete(props.id);
  simArgs.value.nodes.set(props.id, {
    type: 'Sum',
    symbol: opts.symbol
  });
  const num = opts.symbol.slice(1, -1).length;
  if (num > 5) {
    msg.error('和块最多五个输入!');
  } else if (num < 1) {
    msg.error('和块至少一个输入!');
  }
  const comps = [c];
  const handles = ids.slice(0, num).map((x: any) => {
    const p = Math.floor(180 / (num + 1)) * x.num;
    const sourceHandleStyle = {
      top: String(p).concat('px'),
      backgroundColor: 'red'
    };
    return h(Handle, {
      id: x.id,
      type: 'target',
      position: Position.Left,
      isValidConnection: conn => Func(conn, nodes.value),
      style: sourceHandleStyle
    });
  });
  const spans = [];
  for (const id of ids.slice(0, num)) {
    spans.push(
      h(
        'span',
        {
          class: 'sum-block-span'
        },
        opts.symbol[id.num]
      )
    );
    spans.push(h('br'));
  }
  const mydiv = h('div', spans);
  for (const handle of handles) {
    comps.push(handle);
  }
  comps.push(mydiv);
  return h('div', comps);
}
</script>

<template>
  <NButton class="sum-block" @dblclick="show = true">
    <SumNode />
  </NButton>
  <div>{{ props.id }}</div>
  <n-drawer v-model:show="show" :width="502">
    <n-drawer-content title="基本传函参数设置" closable>
      <n-input v-model:value="opts.symbol" placeholder="[+]">
        <template #prefix>和块节点符号:</template>
      </n-input>
    </n-drawer-content>
  </n-drawer>
</template>
