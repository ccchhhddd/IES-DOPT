<script setup lang="ts">
import { inject } from 'vue';
import { Handle, Position } from '@vue-flow/core';
import Func from './somefuncs';
const nodes = inject('sysNodes');
</script>

<template>
  <Handle
    id="a"
    type="source"
    :position="Position.Right"
    :is-valid-connection="conn => Func(conn, nodes)"
    :style="{
      backgroundColor: 'blue'
    }"
  />
  <slot name="handle"></slot>
  <svg xmlns="http://www.w3.org/2000/svg" version="1.1">
    <circle cx="48" cy="75" r="46" stroke="black" stroke-width="4" fill="rgb(255, 255, 255)" />
    <line x1="16" y1="43" x2="80" y2="107" style="stroke: rgb(9, 9, 9); stroke-width: 4" />
    <line x1="80" y1="43" x2="16" y2="107" style="stroke: rgb(5, 5, 5); stroke-width: 4" />
    <slot name="text"></slot>
  </svg>
</template>
