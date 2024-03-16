<script setup lang="ts">
import { h, inject, reactive, ref, type Ref } from 'vue';
import { NDrawer, NDrawerContent, NInput, NButton, useMessage } from 'naive-ui';
import { Handle, Position } from '@vue-flow/core';
import Logo from './SumPointLogo.vue';
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
  label: 'SumPoint',
  symbol: '[+]'
});

if (simArgs.value.nodes.has(props.id)) {
  opts.symbol = simArgs.value.nodes.get(props.id).symbol;
} else {
  simArgs.value.nodes.set(props.id, opts.symbol);
}

const ids = [
  {
    id: 'b'
  },
  {
    id: 'c'
  },
  {
    id: 'd'
  }
];

const msg = useMessage();

function SumHandle() {
  if (show.value) {
    return h(Handle, {
      id: 'b',
      type: 'source',
      position: Position.Left,
      isValidConnection: conn => Func(conn, nodes.value),
      style: {
        backgroundColor: 'blue'
      }
    });
  }
  simArgs.value.nodes.delete(props.id);
  simArgs.value.nodes.set(props.id, {
    type: 'Sum',
    symbol: opts.symbol
  });
  const num = opts.symbol.slice(1, -1).length;
  if (num > 3) {
    msg.error('和点最多三个入口');
  } else if (num < 1) {
    msg.error('和点至少有一个入口');
  }
  return ids.slice(0, num).map((x: any) => {
    switch (x.id) {
      case 'b':
        return h(Handle, {
          id: 'b',
          type: 'target',
          position: Position.Left,
          isValidConnection: conn => Func(conn, nodes.value),
          style: {
            backgroundColor: 'red'
          }
        });
      case 'c':
        return h(Handle, {
          id: 'c',
          type: 'target',
          position: Position.Bottom,
          isValidConnection: conn => Func(conn, nodes.value),
          style: {
            backgroundColor: 'red'
          }
        });
      case 'd':
        return h(Handle, {
          id: 'd',
          type: 'target',
          position: Position.Top,
          isValidConnection: conn => Func(conn, nodes.value),
          style: {
            backgroundColor: 'red'
          }
        });
    }
  });
}

function SumSybol() {
  if (show.value) {
    return h(
      'text',
      {
        x: '10',
        y: '85',
        class: 'sum-point-symbol'
      },
      '+'
    );
  }
  simArgs.value.nodes.delete(props.id);
  simArgs.value.nodes.set(props.id, {
    type: 'Sum',
    symbol: opts.symbol
  });
  const num = opts.symbol.slice(1, -1).length;
  return ids.slice(0, num).map((x: any) => {
    switch (x.id) {
      case 'b':
        return h(
          'text',
          {
            x: '10',
            y: '85',
            class: 'sum-point-symbol'
          },
          opts.symbol[1]
        );
      case 'c':
        return h(
          'text',
          {
            x: '40',
            y: '115',
            class: 'sum-point-symbol'
          },
          opts.symbol[2]
        );
      case 'd':
        return h(
          'text',
          {
            x: '40',
            y: '55',
            class: 'sum-point-symbol'
          },
          opts.symbol[3]
        );
    }
  });
}
</script>

<template>
  <NButton class="sum-point" @dblclick="show = true">
    <Logo>
      <template #handle>
        <SumHandle />
      </template>
      <template #text>
        <SumSybol />
      </template>
    </Logo>
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
