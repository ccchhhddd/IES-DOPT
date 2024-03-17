<template>
    <n-divider title-placement="center">{{ props.title + props.description }}制氢综合能源</n-divider>

    <!-- 第一行模式选择与地区选择 -->
    <n-grid :x-gap="16" :y-gap="16" :item-responsive="true" class="pb-15px">
      <!-- 模式选择-->
      <n-grid-item span="0:24 640:24 1024:12">
        <n-card :bordered="false" class="rounded-16px shadow-sm">
          <p class="text-16px font-bold inline-block">场景选择</p>
          <p class="text-16px text-red inline-block">*</p>
          <!-- 在文字后面显示下拉框 -->
          <n-select
            v-model:value="modeChoosed"
            :options="modeOptions"
            style=""
            class="py-5px"
            @update:value="updateModeSelectData"
          />
        </n-card>
      </n-grid-item>
      <!-- 地区选择 -->
      <n-grid-item span="0:24 640:24 1024:12">
        <n-card :bordered="false" class="rounded-16px shadow-sm">
          <p class="text-16px font-bold inline-block">地区选择</p>
          <p class="text-16px text-red inline-block">*</p>
          <n-select v-model:value="regionChoosed" :options="regionOptions" class="py-5px" />
        </n-card>
      </n-grid-item>
    </n-grid>

    <!-- 第二行系统图与风光环境数据图 -->
    <n-grid :x-gap="16" :y-gap="16" :item-responsive="true" class="pb-15px">
      <!-- 系统图 -->
      <n-grid-item span="0:24 640:24 1024:12">
        <n-card :bordered="false" class="rounded-16px shadow-sm">
          <n-space justify="center">
            <p class="text-28px font-bold pb-12px">系统图</p>
          </n-space>
          <n-space v-if="modeChoosed == 1" justify="center">
            <n-image src="/离网制氢系统结构图.jpg" alt="mode-choice" width="600" />
          </n-space>
        </n-card>
      </n-grid-item>
      <!-- 风光环境数据图 -->
      <n-grid-item span="0:24 640:24 1024:12">
        <n-card :bordered="false" class="rounded-16px shadow-sm">
          <n-space justify="center">
            <p class="text-24px font-bold pb-12px">风光环境数据图</p>
            <n-switch v-model:value="dayOrWeek" size="large" class='pt-15px' @update:value="updateSwich">
            <template #checked> 周数据图 </template>
            <template #unchecked> 日数据图 </template>
          </n-switch>
          </n-space>
                  <n-slider v-if="!dayOrWeek" v-model:value="dayChoiceSlider" :step="1" :max="365" :min="1"
          :on-update:value="updateFigure" />
          <n-slider v-else :value="dayChoiceSlider" :step="1" :max="52" :min="1" :on-update:value="updateFigure" />
          <div ref='envFigureRef' class='w-full h-325px' style="margin-top: 15px;"></div>
        </n-card>
      </n-grid-item>
    </n-grid>

    <n-space vertical>
      <!-- 第三行选择优化目标 -->
      <n-card :bordered="false" class="rounded-16px shadow-sm">
        <n-row>
          <p class="text-16px font-bold inline-block">选择优化目标</p>
          <p class="text-16px text-red inline-block">*</p>
        </n-row>
        <n-radio-group v-model:value="items">
          <n-radio-button key="1" value="1" label="氢气成本最低" size="large" />
          <n-radio-button key="2" value="2" label="氢气产能最大" size="large" />
          <n-radio-button key="3" value="3" label="总投资成本最低" size="large" />
        </n-radio-group>
      </n-card>
      <!-- 第四行选择求解器 -->
      <n-card :bordered="false" class="rounded-16px shadow-sm">
        <p class="text-16px font-bold inline-block">选择求解器</p>
        <p class="text-16px text-red inline-block">*</p>
        <n-select v-model:value="solverChoosed" :options="solverOptions" style="" class="py-5px" />
      </n-card>

      <!-- 第五行仿真优化参数输入 -->
      <n-card class="rounded-16px shadow-sm">
        <n-tabs type="line" size="large" :tabs-padding="20" pane-style="padding: 20px;">
          <n-tab-pane name="仿真计算参数输入">
            <n-spin size="large" :show="isCalculating">
              <template #description>正在计算中，请稍等...</template>
              <n-tabs type="line">
                <!-- simulationParamsInput仿真参数 -->
                <n-tab-pane v-for="(val, key, ind) in simulationParamsInput" :name="key">
                  <!-- 经济型分析参数不用显示设备型号选择 -->
                  <template v-if="key !== '经济性分析参数'">
                    <!-- 显示设备1的参数 -->
                    <n-modal v-model:show="showmodal[key]['1']">
                      <n-card
                        style="width: 600px; margin-bottom: 140px"
                        title="参数详情"
                        :bordered="false"
                        size="huge"
                        role="dialog"
                        aria-modal="true"
                      >
                        <n-list>
                          <template v-for="(val_input, key_input, _) in (val['1'] as { [key: string]: number; })">
                            <n-list-item v-if="key_input !== '机组数量'">
                              <p>{{ key_input }}：{{ val_input.toString() }}</p>
                            </n-list-item>
                          </template>
                        </n-list>
                      </n-card>
                    </n-modal>
                    <!-- 显示设备2的参数 -->
                    <n-modal v-model:show="showmodal[key]['2']">
                      <n-card
                        style="width: 600px; margin-bottom: 140px"
                        title="参数详情"
                        :bordered="false"
                        size="huge"
                        role="dialog"
                        aria-modal="true"
                      >
                        <n-list>
                          <template v-for="(val_input, key_input, _) in (val['2'] as { [key: string]: number; })">
                            <n-list-item v-if="key_input !== '机组数量'">
                              <p>{{ key_input }}：{{ val_input.toString() }}</p>
                            </n-list-item>
                          </template>
                        </n-list>
                      </n-card>
                    </n-modal>
                  </template>

                  <!-- 设备型号选择字样 -->
                  <n-row>
                    <p v-if="key !== '经济性分析参数'" class="text-16px font-bold inline-block" style="height: 30px">
                      设备型号选择
                    </p>
                  </n-row>

                  <!-- 显示设备参数按钮 -->
                  <n-space>
                    <n-radio-group v-model:value="device_selected_simulation[key]">
                      <n-space v-for="(device, index) in devices[key]">
                        <n-radio :key="index" :value="index" />
                        <n-space vertical>
                          <n-button strong secondary type="info" size="tiny" @click="showmodal[key][index] = true">
                            显示参数
                          </n-button>
                          <n-image :src="device" width="200" />
                        </n-space>
                      </n-space>
                    </n-radio-group>
                  </n-space>

                  <n-collapse :accordion="true">
                    <p class="text-16px font-bold inline-block" style="height: 30px">参数设置</p>
                    <n-space vertical justify="space-between" size="large" style="margin-bottom: 10px">
                      <!-- 除了经济性分析参数，其他参数只用输入机组数量 -->
                      <n-input-number
                        v-if="key !== '经济性分析参数'"
                        v-model:value="val[device_selected_simulation[key]]['机组数量']"
                        :placeholder="val[device_selected_simulation[key]].toString()"
                        :parse="parse"
                        :format="format"
                      >
                        <template #prefix>机组数量：</template>
                      </n-input-number>

                      <!-- 显示经济分析对应的参数 -->
                      <!-- 不同优化目标下经济性分析参数不同 -->
                      <!-- 优化目标为1的时候不显示投资金额和制氢量 -->
                      <!-- 优化目标为2的时候显示投资金额 不显示制氢量 -->
                      <!-- 优化目标为3的时候显示制氢量 不显示投资金额 -->
                      <!-- 用items做判断 -->
                      <n-input-number
                        v-for="(val_input, key_input, _) in (val as { [key: string]: number; })"
                        v-if="key === '经济性分析参数'"
                        v-model:value="val[key_input as keyof typeof val]"
                        :placeholder="val_input.toString()"
                        :parse="parse"
                        :format="format"
                      >
                        <template #prefix>{{ key_input }}：</template>
                      </n-input-number>
                    </n-space>

                    <!-- 分割线 -->
                    <n-divider></n-divider>
                  </n-collapse>
                </n-tab-pane>
              </n-tabs>
              <!-- 点击仿真按钮触发事件simulationToServer -->
              <n-button size="large" type="info" strong round style="width: 100%" :on-click="simulationToServer">
                点击进行仿真计算
              </n-button>
            </n-spin>
          </n-tab-pane>

          <n-tab-pane name="优化计算参数输入">
            <n-spin size="large" :show="isCalculating">
              <template #description>正在计算中，请稍等......</template>

              <!-- 下拉框选择待优化容量参数 -->
              <p class="text-16px font-bold inline-block">选择待优化容量参数</p>
              <n-select
                v-model:options="isOptimizationOptions"
                v-model:value="isOptimizationGroup"
                multiple
                placeholder="选择容量优化参数"
                style="margin-bottom: 15px; margin-top: 5px"
              />

              <n-tabs type="line">
                <!-- 优化参数选择 -->
                <!-- optParamsInput优化参数 -->
                <n-tab-pane v-for="(val, key, ind) in optParamsInput" :name="key">
                  <template v-if="key !== '经济性分析参数'">
                    <!-- 显示设备1的参数 -->
                    <n-modal v-model:show="showmodal[key]['1']">
                      <n-card
                        style="width: 600px; margin-bottom: 140px"
                        title="参数详情"
                        :bordered="false"
                        size="huge"
                        role="dialog"
                        aria-modal="true"
                      >
                        <n-list>
                          <template v-for="(val_input, key_input, _) in (val['1'] as { [key: string]: number; })">
                            <n-list-item v-if="key_input !== '机组数量'">
                              <p>{{ key_input }}：{{ val_input.toString() }}</p>
                            </n-list-item>
                          </template>
                        </n-list>
                      </n-card>
                    </n-modal>

                    <!-- 显示设备2的参数 -->
                    <n-modal v-model:show="showmodal[key]['2']">
                      <n-card
                        style="width: 600px; margin-bottom: 140px"
                        title="参数详情"
                        :bordered="false"
                        size="huge"
                        role="dialog"
                        aria-modal="true"
                      >
                        <n-list>
                          <template v-for="(val_input, key_input, _) in (val['2'] as { [key: string]: number; })">
                            <n-list-item v-if="key_input !== '机组数量'">
                              <p>{{ key_input }}：{{ val_input.toString() }}</p>
                            </n-list-item>
                          </template>
                        </n-list>
                      </n-card>
                    </n-modal>
                  </template>

                  <!-- 设备型号选择字样 -->
                  <n-row>
                    <p v-if="key !== '经济性分析参数'" class="text-16px font-bold inline-block" style="height: 30px">
                      设备型号选择
                    </p>
                  </n-row>

                  <!-- 显示设备参数按钮 -->
                  <n-space>
                    <n-radio-group v-model:value="device_selected_opt[key]">
                      <n-space v-for="(device, index) in devices[key]">
                        <n-radio :key="index" :value="index" />
                        <n-space vertical>
                          <n-button strong secondary type="info" size="tiny" @click="showmodal[key][index] = true">
                            显示参数
                          </n-button>
                          <n-image :src="device" width="200" />
                        </n-space>
                      </n-space>
                    </n-radio-group>
                  </n-space>

                  <!-- 显示经济分析对应的参数 -->
                  <n-collapse :accordion="true">
                    <p class="text-16px font-bold inline-block" style="height: 30px">参数设置</p>
                    <n-space vertical justify="space-between" size="large" style="margin-bottom: 10px">
                      <n-input-number
                        v-if="key !== '经济性分析参数'"
                        v-model:value="val[device_selected_opt[key]]['机组数量']"
                        :placeholder="val[device_selected_opt[key]].toString()"
                        :parse="parse"
                        :format="format"
                      >
                        <template #prefix>机组数量：</template>
                      </n-input-number>

                      <!-- 显示经济分析对应的参数 -->
                      <!-- 不同优化目标下经济性分析参数不同 -->
                      <!-- 优化目标为1的时候不显示投资金额和制氢量 -->
                      <!-- 优化目标为2的时候显示投资金额 不显示制氢量 -->
                      <!-- 优化目标为3的时候显示制氢量 不显示投资金额 -->
                      <!-- 用items做判断 -->
                      <n-input-number
                        v-for="(val_input, key_input, _) in (val as { [key: string]: number; })"
                        v-if="key === '经济性分析参数'"
                        v-model:value="val[key_input as keyof typeof val]"
                        :placeholder="val_input.toString()"
                        :parse="parse"
                        :format="format"
                      >
                        <template #prefix>{{ key_input }}：</template>
                      </n-input-number>
                    </n-space>

                    <!-- 分割线 -->
                    <n-divider></n-divider>
                  </n-collapse>
                </n-tab-pane>
              </n-tabs>
              <!-- 点击优化按钮触发事件optToServer -->
              <n-button size="large" type="info" strong round style="width: 100%" :on-click="optToServer">
                点击进行优化计算
              </n-button>
            </n-spin>
          </n-tab-pane>
        </n-tabs>
      </n-card>

      <!-- 分割线 -->
      <n-divider title-placement="center">结果输出</n-divider>


          <!-- 第六行系统小时运行图和制氢量图 -->
  <n-grid :x-gap="16" :y-gap="16" :item-responsive="true" class="pb-15px">
          <n-grid-item span='0:24 640:24 1024:12'>
      <!-- 系统小时运行图 -->
      <n-card :bordered="false" class="rounded-16px shadow-sm">
        <n-space justify="center">
          <p class="text-24px font-bold pb-12px">系统小时运行图</p>
                  <n-switch v-model:value="dayOrWeek" size="large" class='pt-15px' @update:value="updateSwich">
            <template #checked> 周数据图 </template>
            <template #unchecked> 日数据图 </template>
          </n-switch>
        </n-space>
        <!-- 天数选择 -->
        <n-slider
          v-if="!dayOrWeek"
          v-model:value="dayChoiceSlider"
          :step="1"
          :max="365"
          :min="1"
          :on-update:value="updateFigure"
        />
        <n-slider v-else v-model:value="dayChoiceSlider" :step="1" :max="52" :min="1" :on-update:value="updateFigure" />
        <!-- 图表 -->
        <div ref="lineRef" class="w-full h-640px" style="margin-top: 15px"></div>
      </n-card>
      </n-grid-item>

      <n-grid-item span='0:24 640:24 1024:12'>
              <!-- 制氢量图 -->
              <n-card :bordered="false" class="rounded-16px shadow-sm">
            <n-space justify="center">
          <p class="text-24px font-bold pb-12px">制氢量图</p>
                  <n-switch v-model:value="dayOrWeek" size="large" class='pt-15px' @update:value="updateSwich">
            <template #checked> 周数据图 </template>
            <template #unchecked> 日数据图 </template>
          </n-switch>
            </n-space>
            <!-- 天数选择 -->
            <n-slider
          v-if="!dayOrWeek"
          v-model:value="dayChoiceSlider"
          :step="1"
          :max="365"
          :min="1"
          :on-update:value="updateFigure"
        />
        <n-slider v-else v-model:value="dayChoiceSlider" :step="1" :max="52" :min="1" :on-update:value="updateFigure" />
        <!-- 图表 -->
        <div ref="lineRef1" class="w-full h-640px" style="margin-top: 15px"></div>
      </n-card>
      </n-grid-item>
  </n-grid>

      <!-- 输出规模与经济性表，并支持Excel导出 -->
      <n-card :bordered="false" class="rounded-16px shadow-sm">
        <n-space justify="center">
          <p class="text-24px font-bold pb-12px">规模与经济性表</p>
          <n-button type="success" round :on-click="excelExport" style="margin-top: 3px">
            {{ tableData.length }}条数据，导出Excel表格
          </n-button>
        </n-space>
        <n-data-table :columns="tableColumns" :data="tableData" :pagination="{ pageSize: 10 }" :single-line="false" />
      </n-card>
    </n-space>
  </template>

  <script setup lang="ts">
  import type { CSSProperties, Ref } from 'vue';
  import { ref } from 'vue';
  import type { SelectOption } from 'naive-ui';
  import { useMessage } from 'naive-ui';
  import * as XLSX from 'xlsx';
  import { type ECOption, useEcharts } from '@/composables';
  import { request } from '@/service/request/index';
  import { isNull,range } from 'lodash-es';

  const COLORS = ["#009ad6", "#fcaf17", "#9AFF02", "#4f5555", "#8552a1", "#548C00", "#a1a3a6", "#fedcbd"]
  // 定义子组件参数childrenParams，测试用，不影响主组件
  const props = defineProps({
    title: {
      type: String,
      default: ''
    },
    description: {
      type: String,
      default: ''
    }
  });
  const items = ref('1');
  const modeChoosed = ref<number>(1); //  模式选择: 1.离网制氢模式
  const regionChoosed = ref<number>(1); //  地区选择: 1.榆林，2.若羌，3.冷湖，4.西海
  const solverChoosed = ref<string>('resampling_memetic_search'); //	求解器选择: 1.resampling_memetic_search, 2.separable_nes, 3.generating_set_search, 4.simultaneous_perturbation_stochastic_approximation, 5.adaptive_de_rand_1_bin

  const dayOrWeek = ref<boolean>(false); //	天数据或周数据选择: false.天数据，true.周数据

  const isCalculating = ref<boolean>(false); //	是否正在计算中
  // 滑动条数据
  const dayChoiceSlider = ref<number>(1); //	天数选择滑动条


  // 模式选择选项
  const modeOptions = [
    {
      label: '离网制氢模式',
      value: 1
    }
  ];

  const regionOptions = [
    {
      label: '榆林',
      value: 1
    },
    {
      label: '若羌',
      value: 2
    },
    {
      label: '冷湖',
      value: 3
    },
    {
      label: '西海',
      value: 4
    }
  ]; //	地区选择选项
  const solverOptions = [
    {
      label: 'resampling_memetic_search',
      value: 'resampling_memetic_search'
    },
    {
      label: 'separable_nes',
      value: 'separable_nes'
    },
    {
      label: 'generating_set_search',
      value: 'generating_set_search'
    },
    {
      label: 'simultaneous_perturbation_stochastic_approximation',
      value: 'simultaneous_perturbation_stochastic_approximation'
    },
    {
      label: 'adaptive_de_rand_1_bin',
      value: 'adaptive_de_rand_1_bin'
    }
  ]; //	求解器选择选项

  const devices = {
    风电参数: { 1: '/风机设备1.webp', 2: '/风机设备2.webp' },
    光电参数: { 1: '/光伏设备1.webp', 2: '/光伏设备2.webp' },
    气电参数: { 1: '/燃气轮机设备1.png', 2: '/燃气轮机设备2.png' },
    整流器参数: { 1: '/整流器设备1.webp', 2: '/整流器设备2.jpeg' },
    压缩空气储能参数: { 1: '/压缩空气储能设备1.png', 2: '/压缩空气储能设备2.png' },
    电解槽参数: { 1: '/电解槽设备1.jpeg', 2: '/电解槽设备2.jpeg' },
    氢气压缩机参数: { 1: '/氢气压缩机设备1.jpeg', 2: '/氢气压缩机设备2.jpeg' },
    储氢罐参数: { 1: '/储氢罐设备1.webp', 2: '/储氢罐设备2.webp' }
  }; //	设备图片

  const device_selected_simulation = ref({
    风电参数: '1',
    光电参数: '1',
    气电参数: '1',
    整流器参数: '1',
    压缩空气储能参数: '1',
    电解槽参数: '1',
    氢气压缩机参数: '1',
    储氢罐参数: '1'
  }); //	仿真模式下设备选择

  const device_selected_opt = ref({
    风电参数: '1',
    光电参数: '1',
    气电参数: '1',
    整流器参数: '1',
    压缩空气储能参数: '1',
    电解槽参数: '1',
    氢气压缩机参数: '1',
    储氢罐参数: '1'
  }); //	优化模式下设备选择

  const showmodal = ref({
    风电参数: { 1: false, 2: false },
    光电参数: { 1: false, 2: false },
    气电参数: { 1: false, 2: false },
    整流器参数: { 1: false, 2: false },
    压缩空气储能参数: { 1: false, 2: false },
    电解槽参数: { 1: false, 2: false },
    氢气压缩机参数: { 1: false, 2: false },
    储氢罐参数: { 1: false, 2: false }
  }); //	设备参数显示

  // echarts图表
  const lineOptions = ref<ECOption>({
    //  显示工具箱
    toolbox: {
      show: true,
      orient: 'vertical',
      feature: {
        //  保存为图片，背景为白色
        saveAsImage: {
          show: true,
          type: 'png',
          pixelRatio: 4,
        },
        //  显示缩放按钮
        dataZoom: {
          show: true
        },
        //  显示类型切换按钮
        magicType: {
          show: true,
          type: ['stack', 'line', 'bar']
        },
        dataView: {
          show: true,                         // 是否显示该工具。
          title: '数据视图',
          readOnly: false,                    // 是否不可编辑（只读）
          lang: ['数据视图', '关闭', '刷新'],  // 数据视图上有三个话术，默认是['数据视图', '关闭', '刷新']
          backgroundColor: '#fff',             // 数据视图浮层背景色。
          textareaColor: '#fff',               // 数据视图浮层文本输入区背景色
          textareaBorderColor: '#333',         // 数据视图浮层文本输入区边框颜色
          textColor: '#000',                    // 文本颜色。
          buttonColor: '#c23531',              // 按钮颜色。
          buttonTextColor: '#fff',             // 按钮文本颜色。
        },
      }
    },
    tooltip: {
      trigger: 'axis',
      axisPointer: {
        type: 'cross',
        label: {
          backgroundColor: '#6a7985'
        }
      }
    },
    legend: {
      data: ['下载量', '注册数']
    },
    grid: {
      left: '3%',
      right: '4%',
      bottom: '3%',
      containLabel: true
    },
    xAxis: {
      type: 'category',
      data: ['06:00', '08:00', '10:00', '12:00', '14:00', '16:00', '18:00', '20:00', '22:00', '24:00'],
      name: '小时数',
      axisLabel: {
        formatter: '{value} h'
      }
    },
    yAxis: [
      {
        type: 'value',
        name: '功率/万kW',
        axisLabel: {
          formatter: '{value}'
        }
      }
    ],
    series: [
      {
        name: '下载量',
        type: 'line',
        smooth: true,
        showSymbol: false,
        stack: 'Total',
        areaStyle: {},
        emphasis: {
          focus: 'series'
        },
        data: [4623, 6145, 6268, 6411, 1890, 4251, 2978, 3880, 3606, 4311]
      },
      {
        name: '注册数',
        type: 'line',
        smooth: true,
        showSymbol: false,
        stack: 'Total',
        areaStyle: {},
        emphasis: {
          focus: 'series'
        },
        data: [2208, 2016, 2916, 4512, 8281, 2008, 1963, 2367, 2956, 678]
      }
    ]
  }) as Ref<ECOption>;
  const { domRef: lineRef } = useEcharts(lineOptions);

  // echarts图表
  const lineOptions1 = ref<ECOption>({
    //  显示工具箱
    toolbox: {
      show: true,
      orient: 'vertical',
      feature: {
        //  保存为图片，背景为白色
        saveAsImage: {
          show: true,
          type: 'png',
          pixelRatio: 4,
        },
        //  显示缩放按钮
        dataZoom: {
          show: true
        },
        //  显示类型切换按钮
        magicType: {
          show: true,
          type: ['stack', 'line', 'bar']
        },
        dataView: {
          show: true,                         // 是否显示该工具。
          title: '数据视图',
          readOnly: false,                    // 是否不可编辑（只读）
          lang: ['数据视图', '关闭', '刷新'],  // 数据视图上有三个话术，默认是['数据视图', '关闭', '刷新']
          backgroundColor: '#fff',             // 数据视图浮层背景色。
          textareaColor: '#fff',               // 数据视图浮层文本输入区背景色
          textareaBorderColor: '#333',         // 数据视图浮层文本输入区边框颜色
          textColor: '#000',                    // 文本颜色。
          buttonColor: '#c23531',              // 按钮颜色。
          buttonTextColor: '#fff',             // 按钮文本颜色。
        },
      }
    },
    tooltip: {
      trigger: 'axis',
      axisPointer: {
        type: 'cross',
        label: {
          backgroundColor: '#6a7985'
        }
      }
    },
    legend: {
      data: ['下载量', '注册数']
    },
    grid: {
      left: '3%',
      right: '4%',
      bottom: '3%',
      containLabel: true
    },
    xAxis: {
      type: 'category',
      data: ['06:00', '08:00', '10:00', '12:00', '14:00', '16:00', '18:00', '20:00', '22:00', '24:00'],
      name: '小时数',
      axisLabel: {
        formatter: '{value} h'
      }
    },
    yAxis: [
      {
        type: 'value',
        name: 'kg',
        axisLabel: {
          formatter: '{value}'
        }
      }
    ],
    series: [
      {
        name: '下载量',
        type: 'line',
        smooth: true,
        showSymbol: false,
        stack: 'Total',
        areaStyle: {},
        emphasis: {
          focus: 'series'
        },
        data: [4623, 6145, 6268, 6411, 1890, 4251, 2978, 3880, 3606, 4311]
      },
      {
        name: '注册数',
        type: 'line',
        smooth: true,
        showSymbol: false,
        stack: 'Total',
        areaStyle: {},
        emphasis: {
          focus: 'series'
        },
        data: [2208, 2016, 2916, 4512, 8281, 2008, 1963, 2367, 2956, 678]
      }
    ]
  }) as Ref<ECOption>;
  const { domRef: lineRef1 } = useEcharts(lineOptions1);

  // 风光环境数据图
  const envFigureOptions = ref<ECOption>({
    //  显示工具箱
    toolbox: {
      show: true,
      orient: 'vertical',
      feature: {
        //  保存为图片，背景为白色
        saveAsImage: {
          show: true,
          type: 'png',
          pixelRatio: 4,
        },
        //  显示缩放按钮
        dataZoom: {
          show: true
        },
        //  显示类型切换按钮
        magicType: {
          show: true,
          type: ['stack', 'line', 'bar']
        },
        dataView: {
          show: true,                         // 是否显示该工具。
          title: '数据视图',
          readOnly: false,                    // 是否不可编辑（只读）
          lang: ['数据视图', '关闭', '刷新'],  // 数据视图上有三个话术，默认是['数据视图', '关闭', '刷新']
          backgroundColor: '#fff',             // 数据视图浮层背景色。
          textareaColor: '#fff',               // 数据视图浮层文本输入区背景色
          textareaBorderColor: '#333',         // 数据视图浮层文本输入区边框颜色
          textColor: '#000',                    // 文本颜色。
          buttonColor: '#c23531',              // 按钮颜色。
          buttonTextColor: '#fff',             // 按钮文本颜色。
        },
      }
    },
    tooltip: {
      trigger: 'axis',
      axisPointer: {
        type: 'cross',
        label: {
          backgroundColor: '#6a7985'
        }
      }
    },
    legend: {
      data: ['辐射强度', '风速'],
      textStyle: {
        fontSize: 20
      },
    },
    grid: {
      left: '3%',
      right: '4%',
      bottom: '3%',
      containLabel: true
    },
    xAxis: {
      type: 'category',
      data: ['06:00', '08:00', '10:00', '12:00', '14:00', '16:00', '18:00', '20:00', '22:00', '24:00'],
      name: '小时数',
      axisLabel: {
        formatter: '{value} h'
      }
    },
    yAxis: [

      {
        type: 'value',
        position: 'right',
        name: '风速 / m/s',
        axisLabel: {
          formatter: '{value}'
        }
      },
			{
        type: 'value',
        position: 'left',
        name: '辐照度/ W/m^2',
        axisLabel: {
          formatter: '{value}'
        }
      },

    ],
    series: [

      {
        name: '风速',
        type: 'line',
        smooth: true,
        showSymbol: false,
        yAxisIndex: 1,
        // stack: 'Total',
        // areaStyle: {},
        emphasis: {
          focus: 'series'
        },
        data: [2208, 2016, 2916, 4512, 8281, 2008, 1963, 2367, 2956, 678]
      },
			{
        name: '辐射强度',
        type: 'line',
        smooth: true,
        showSymbol: false,
        yAxisIndex: 0,
        // stack: '',
        // areaStyle: {},
        emphasis: {
          focus: 'series'
        },
        data: [4623, 6145, 6268, 6411, 1890, 4251, 2978, 3880, 3606, 4311]
      },
    ]
  }) as Ref<ECOption>;
  const { domRef: envFigureRef } = useEcharts(envFigureOptions);



  // 表格数据类型
  type TableData = {
    [key: string]: number;
  };

  // 图表数据类型
  type FigureData = {
    xAxis: Array<number>
    yAxis: {
      [key: string]: Array<number>
    }
  };

  // 后端接受数据类型
  type BackEndData = {
    table: TableData;
    figure: FigureData;
      envFigure: FigureData;
  };

  // 表格数据
  const simulationParamsInput = ref({
    风电参数: {
      1: {
        机组数量: 2500,
        '单机容量(kw)': 1500,
        '使用年限(年)': 15,
        '初始成本(元/kw)': 4800,
        '年运维成本(元/kw)': 720,
        '更换成本(元/kw)': 4800,
        风轮传动效率: 0.96,
        发电机效率: 0.93,
        '风速切入速度(m/s)': 10,
        '风速切出速度(m/s)': 135,
        '截止风速速度(m/s)': 150
      },
      2: {
        机组数量: 2500,
        '单机容量(kw)': 2000,
        '使用年限(年)': 20,
        '初始成本(元/kw)': 6000,
        '年运维成本(元/kw)': 800,
        '更换成本(元/kw)': 5000,
        风轮传动效率: 0.9,
        发电机效率: 0.97,
        '风速切入速度(m/s)': 15,
        '风速切出速度(m/s)': 150,
        '截止风速速度(m/s)': 175
      }
    },
    光电参数: {
      1: {
        机组数量: 1.0e5,
        '单机容量(kw)': 3.5,
        '使用年限(年)': 15,
        '初始成本(元/kw)': 3800,
        '年运维成本(元/kw)': 190,
        '更换成本(元/kw)': 3800,
        '光伏板面积(m2)': 3.1,
        光伏板温度系数: 0.0034
      },
      2: {
        机组数量: 1.0e5,
        '单机容量(kw)': 5,
        '使用年限(年)': 20,
        '初始成本(元/kw)': 4500,
        '年运维成本(元/kw)': 230,
        '更换成本(元/kw)': 4500,
        '光伏板面积(m2)': 4.5,
        光伏板温度系数: 0.004
      }
    },
    气电参数: {
      1: {
        机组数量: 5,
        '单机容量(kw)': 6.5e4,
        '使用年限(年)': 15,
        '初始成本(元/kw)': 4800,
        '年运维成本(元/kw)': 160,
        '更换成本(元/kw)': 4800,
        最小出力效率: 0.2,
        出力调整系数: 0.05,
        发电效率: 0.6
      },
      2: {
        机组数量: 5,
        '单机容量(kw)': 8.0e4,
        '使用年限(年)': 20,
        '初始成本(元/kw)': 5000,
        '年运维成本(元/kw)': 250,
        '更换成本(元/kw)': 5500,
        最小出力效率: 0.25,
        出力调整系数: 0.04,
        发电效率: 0.7
      }
    },
    整流器参数: {
      1: {
        机组数量: 10,
        '单机容量(kw)': 1500,
        '使用年限(年)': 15,
        '初始成本(元/kw)': 2300,
        '年运维成本(元/kw)': 50,
        '更换成本(元/kw)': 2300,
        综合效率: 0.9
      },
      2: {
        机组数量: 10,
        '单机容量(kw)': 2000,
        '使用年限(年)': 20,
        '初始成本(元/kw)': 3000,
        '年运维成本(元/kw)': 100,
        '更换成本(元/kw)': 3000,
        综合效率: 0.92
      }
    },
    压缩空气储能参数: {
      1: {
        机组数量: 30,
        '单机容量(kw)': 5000,
        '使用年限(年)': 15,
        '初始成本(元/kw)': 3800,
        '年运维成本(元/kw)': 190,
        '更换成本(元/kw)': 3800,
        充电效率: 0.6
      },
      2: {
        机组数量: 30,
        '单机容量(kw)': 6000,
        '使用年限(年)': 20,
        '初始成本(元/kw)': 5000,
        '年运维成本(元/kw)': 250,
        '更换成本(元/kw)': 5000,
        充电效率: 0.65
      }
    },
    电解槽参数: {
      1: {
        机组数量: 100,
        '单机容量(kw)': 5000,
        '使用年限(年)': 15,
        '初始成本(元/kw)': 2000,
        '年运维成本(元/kw)': 100,
        '更换成本(元/kw)': 2000
      },
      2: {
        机组数量: 100,
        '单机容量(kw)': 6000,
        '使用年限(年)': 20,
        '初始成本(元/kw)': 2500,
        '年运维成本(元/kw)': 125,
        '更换成本(元/kw)': 2500
      }
    },
    氢气压缩机参数: {
      1: {
        机组数量: 100,
        '单机容量(kg)': 500,
        '使用年限(年)': 15,
        '初始成本(元/kg)': 2300,
        '年运维成本(元/kg)': 46,
        '更换成本(元/kg)': 2300,
        '单位耗电量(kWh/kg)': 1.0
      },
      2: {
        机组数量: 100,
        '单机容量(kg)': 700,
        '使用年限(年)': 20,
        '初始成本(元/kg)': 3000,
        '年运维成本(元/kg)': 60,
        '更换成本(元/kg)': 3000,
        '单位耗电量(kWh/kg)': 0.9
      }
    },
    储氢罐参数: {
      1: {
        机组数量: 10,
        '单机容量(kg)': 5000,
        '使用年限(年)': 15,
        '初始成本(元/kg)': 2300,
        '年运维成本(元/kg)': 46,
        '更换成本(元/kg)': 2300
      },
      2: {
        机组数量: 10,
        '单机容量(kg)': 7000,
        '使用年限(年)': 20,
        '初始成本(元/kg)': 3000,
        '年运维成本(元/kg)': 60,
        '更换成本(元/kg)': 3000
      }
    },
    经济性分析参数: {
      运行天数: 3650,
      '氢气生产用水成本(元/kg)': 0.021,
      '氢气销售价格(元/kg)': 25.58,
      '天然气价格(元/Nm³)': 1.7,
      单次运输氢气的费用: 250000,
      '投资金额(元)': 1e10,
      '制氢量(kg)': 1e8
    }
  });
  const optParamsInput = ref({
    风电参数: {
      1: {
        机组数量: 2500,
        '单机容量(kw)': 1500,
        '使用年限(年)': 15,
        '初始成本(元/kw)': 4800,
        '年运维成本(元/kw)': 720,
        '更换成本(元/kw)': 4800,
        风轮传动效率: 0.96,
        发电机效率: 0.93,
        '风速切入速度(m/s)': 10,
        '风速切出速度(m/s)': 135,
        '截止风速速度(m/s)': 150
      },
      2: {
        机组数量: 2500,
        '单机容量(kw)': 2000,
        '使用年限(年)': 20,
        '初始成本(元/kw)': 6000,
        '年运维成本(元/kw)': 800,
        '更换成本(元/kw)': 5000,
        风轮传动效率: 0.9,
        发电机效率: 0.97,
        '风速切入速度(m/s)': 15,
        '风速切出速度(m/s)': 150,
        '截止风速速度(m/s)': 175
      }
    },
    光电参数: {
      1: {
        机组数量: 1.0e5,
        '单机容量(kw)': 3.5,
        '使用年限(年)': 15,
        '初始成本(元/kw)': 3800,
        '年运维成本(元/kw)': 190,
        '更换成本(元/kw)': 3800,
        '光伏板面积(m2)': 3.1,
        光伏板温度系数: 0.0034
      },
      2: {
        机组数量: 1.0e5,
        '单机容量(kw)': 5,
        '使用年限(年)': 20,
        '初始成本(元/kw)': 4500,
        '年运维成本(元/kw)': 230,
        '更换成本(元/kw)': 4500,
        '光伏板面积(m2)': 4.5,
        光伏板温度系数: 0.004
      }
    },
    气电参数: {
      1: {
        机组数量: 5,
        '单机容量(kw)': 6.5e4,
        '使用年限(年)': 15,
        '初始成本(元/kw)': 4800,
        '年运维成本(元/kw)': 160,
        '更换成本(元/kw)': 4800,
        最小出力效率: 0.2,
        出力调整系数: 0.05,
        发电效率: 0.6
      },
      2: {
        机组数量: 5,
        '单机容量(kw)': 8.0e4,
        '使用年限(年)': 20,
        '初始成本(元/kw)': 5000,
        '年运维成本(元/kw)': 250,
        '更换成本(元/kw)': 5500,
        最小出力效率: 0.25,
        出力调整系数: 0.04,
        发电效率: 0.7
      }
    },
    整流器参数: {
      1: {
        机组数量: 10,
        '单机容量(kw)': 1500,
        '使用年限(年)': 15,
        '初始成本(元/kw)': 2300,
        '年运维成本(元/kw)': 50,
        '更换成本(元/kw)': 2300,
        综合效率: 0.9
      },
      2: {
        机组数量: 10,
        '单机容量(kw)': 2000,
        '使用年限(年)': 20,
        '初始成本(元/kw)': 3000,
        '年运维成本(元/kw)': 100,
        '更换成本(元/kw)': 3000,
        综合效率: 0.92
      }
    },
    压缩空气储能参数: {
      1: {
        机组数量: 30,
        '单机容量(kw)': 5000,
        '使用年限(年)': 15,
        '初始成本(元/kw)': 3800,
        '年运维成本(元/kw)': 190,
        '更换成本(元/kw)': 3800,
        充电效率: 0.6
      },
      2: {
        机组数量: 30,
        '单机容量(kw)': 6000,
        '使用年限(年)': 20,
        '初始成本(元/kw)': 5000,
        '年运维成本(元/kw)': 250,
        '更换成本(元/kw)': 5000,
        充电效率: 0.65
      }
    },
    电解槽参数: {
      1: {
        机组数量: 100,
        '单机容量(kw)': 5000,
        '使用年限(年)': 15,
        '初始成本(元/kw)': 2000,
        '年运维成本(元/kw)': 100,
        '更换成本(元/kw)': 2000
      },
      2: {
        机组数量: 100,
        '单机容量(kw)': 6000,
        '使用年限(年)': 20,
        '初始成本(元/kw)': 2500,
        '年运维成本(元/kw)': 125,
        '更换成本(元/kw)': 2500
      }
    },
    氢气压缩机参数: {
      1: {
        机组数量: 100,
        '单机容量(kg)': 500,
        '使用年限(年)': 15,
        '初始成本(元/kg)': 2300,
        '年运维成本(元/kg)': 46,
        '更换成本(元/kg)': 2300,
        '单位耗电量(kWh/kg)': 1.0
      },
      2: {
        机组数量: 100,
        '单机容量(kg)': 700,
        '使用年限(年)': 20,
        '初始成本(元/kg)': 3000,
        '年运维成本(元/kg)': 60,
        '更换成本(元/kg)': 3000,
        '单位耗电量(kWh/kg)': 0.9
      }
    },
    储氢罐参数: {
      1: {
        机组数量: 10,
        '单机容量(kg)': 5000,
        '使用年限(年)': 15,
        '初始成本(元/kg)': 2300,
        '年运维成本(元/kg)': 46,
        '更换成本(元/kg)': 2300
      },
      2: {
        机组数量: 10,
        '单机容量(kg)': 7000,
        '使用年限(年)': 20,
        '初始成本(元/kg)': 3000,
        '年运维成本(元/kg)': 60,
        '更换成本(元/kg)': 3000
      }
    },
    经济性分析参数: {
      运行天数: 3650,
      '氢气生产成本(元/kg)': 0.021,
      '氢气销售价格(元/kg)': 25.58,
      '氢气单次运输费用(元/次)': 1e5,
      '天然气价格(元/Nm³)': 1.7,
      '投资金额(元)': 1e11,
      '制氢量(kg)': 1e4
    }
  });
  const isOptimizationGroup = ref([0]); //	优化选项
  const optimizationTime = ref<number>(1); //	优化时间
  const isOptimizationOptions = ref([
    {
      label: '风电容量',
      value: 0
    },
    {
      label: '光电容量',
      value: 1
    },
    {
      label: '气电容量',
      value: 2
    },
    {
      label: '整流器容量',
      value: 3
      // disabled: true
    },
    {
      label: '压缩空气储能容量',
      value: 4
      // disabled: true
    },
    {
      label: '电解槽容量',
      value: 5
      // disabled: true
    },
    {
      label: '氢气压缩机容量',
      value: 6
      // disabled: true
    },
    {
      label: '储氢罐容量',
      value: 7
      // disabled: true
    }
  ]);

  const tableColumns = ref<Array<{ title: string; key: string }>>([]);
  const tableData = ref<TableData[]>([]); // 表格数据
  const figureData = ref<FigureData>({ xAxis: [], yAxis: {} }) // 系统小时运行图数据
  const envFigureData = ref<FigureData>({ xAxis: [], yAxis: {} }) // 环境图数据
  const H2FigureData = ref<FigureData>({ xAxis: [], yAxis: {} }) // 环境图数据


  // 模式选择数据更新
  function updateModeSelectData(value: number, options: SelectOption) {
    if (value == 1) {
      isOptimizationOptions.value[4].disabled = true;
    } else {
      isOptimizationOptions.value[4].disabled = false;
    }
    tableData.value = [];
  }

  // 更新表格数据
  const updateFigure = (dayValue: number) => {
      dayChoiceSlider.value = dayValue;
    let dataRange = dayOrWeek.value ? 24 * 7 : 24;
    // let dataRange2 = dayOrWeek.value ? Array.from({ length: 24 * 7 }, (_, i) => { return `第${toInteger(i / 24)}天 ${i % 24}` }) : range(0, 24);
    let dataRange2 = dayOrWeek.value ? range(0, 24 * 7) : range(0, 24);

    // 环境图数据
    envFigureOptions.value.xAxis = {
      type: 'category',
      data: dataRange2,
      name: '小时数',
      axisLabel: {
        formatter: '{value} h'
      }
    };
    envFigureOptions.value.legend = {
      // 设置图例图标的大小
      textStyle: {
        fontSize: 20
      },
      icon: 'circle',
      itemHeight: 20, // 修改icon图形大小
      data: Object.keys(envFigureData.value.yAxis)
    };
    const envcolors = ["#009ad6","#fcaf17"];
    envFigureOptions.value.series = Object.keys(envFigureData.value.yAxis).map((key, i) => {
      return {
        name: key,
        type: 'line',
        smooth: true,
        showSymbol: false,
        yAxisIndex: i,
        // stack: 'Total',
        // areaStyle: {},
        emphasis: {
          focus: 'series'
        },
        // lineStyle: {
        //   width: 2
        // },
        color: envcolors[i],
        data: envFigureData.value.yAxis[key].slice((dayValue - 1) * dataRange, dayValue * dataRange)
      }
    });

        // 更新系统小时运行数图
    lineOptions.value.xAxis = {
      type: 'category',
      data: dataRange2,
      name: '小时数',
      axisLabel: {
        formatter: '{value} h'
      }
    };
    lineOptions.value.legend = {
      // 设置图例图标的大小
      textStyle: {
        fontSize: 20
      },
      icon: 'circle',
      itemHeight: 20, // 修改icon图形大小
      data: Object.keys(figureData.value.yAxis)
    };
    lineOptions.value.series = Object.keys(figureData.value.yAxis).map((key, i) => {
      return {
        name: key,
        type: 'line',
        smooth: true,
        showSymbol: false,
        stack: 'Total',
        areaStyle: {},
        emphasis: {
          focus: 'series'
        },
        lineStyle: {
          width: 0
        },
        color: COLORS[i],
        data: figureData.value.yAxis[key].slice((dayValue - 1) * dataRange, dayValue * dataRange)
      }
    }
      );
    // 小时图数据
    lineOptions.value.xAxis = {
      type: 'category',
      // data: figureData.value.xAxis.slice((dayValue - 1) * dataRange, dayValue * dataRange),
      data: dataRange2,
      name: '小时数',
      axisLabel: {
        formatter: '{value} h'
      }
    };
    lineOptions.value.legend = {
      // 设置图例图标的大小
      textStyle: {
        fontSize: 20
      },
      icon: 'circle',
      itemHeight: 20, // 修改icon图形大小
      data: Object.keys(figureData.value.yAxis)
    };
    lineOptions.value.series = Object.keys(figureData.value.yAxis).map((key, i) => {
      return {
        name: key,
        type: 'line',
        smooth: true,
        showSymbol: false,
        stack: 'Total',
        areaStyle: {},
        emphasis: {
          focus: 'series'
        },
        lineStyle: {
          width: 0
        },
        color: COLORS[i],
        data: figureData.value.yAxis[key].slice((dayValue - 1) * dataRange, dayValue * dataRange)
      }
    }
      );

      ///////////////////

  // 更新制氢量图
              lineOptions1.value.xAxis = {
      type: 'category',
      data: dataRange2,
      name: '小时数',
      axisLabel: {
        formatter: '{value} h'
      }
    };
    lineOptions1.value.legend = {
      // 设置图例图标的大小
      textStyle: {
        fontSize: 20
      },
      icon: 'circle',
      itemHeight: 20, // 修改icon图形大小
      data: Object.keys(H2FigureData.value.yAxis)
    };
    lineOptions1.value.series = Object.keys(H2FigureData.value.yAxis).map((key, i) => {
      return {
        name: key,
        type: 'line',
        smooth: true,
        showSymbol: false,
        stack: 'Total',
        areaStyle: {},
        emphasis: {
          focus: 'series'
        },
        lineStyle: {
          width: 0
        },
        color: COLORS[i],
        data: H2FigureData.value.yAxis[key].slice((dayValue - 1) * dataRange, dayValue * dataRange)
      }
    }
      );
    // 小时图数据
    lineOptions1.value.xAxis = {
      type: 'category',
      // data: figureData.value.xAxis.slice((dayValue - 1) * dataRange, dayValue * dataRange),
      data: dataRange2,
      name: '小时数',
      axisLabel: {
        formatter: '{value} h'
      }
    };
    lineOptions1.value.legend = {
      // 设置图例图标的大小
      textStyle: {
        fontSize: 20
      },
      icon: 'circle',
      itemHeight: 20, // 修改icon图形大小
      data: Object.keys(H2FigureData.value.yAxis)
    };
    lineOptions1.value.series = Object.keys(H2FigureData.value.yAxis).map((key, i) => {
      return {
        name: key,
        type: 'line',
        smooth: true,
        showSymbol: false,
        stack: 'Total',
        areaStyle: {},
        emphasis: {
          focus: 'series'
        },
        lineStyle: {
          width: 0
        },
        color: COLORS[i],
        data: H2FigureData.value.yAxis[key].slice((dayValue - 1) * dataRange, dayValue * dataRange)
      }
    }
      );




  };

  const message = useMessage();

  const updateSwich = (value: boolean) => {
    dayOrWeek.value = value;
    updateFigure(dayChoiceSlider.value);
  }
  // 从后端获取数据
  function simulationToServer() {
    isCalculating.value = true;
    const input = {};
    for (const [key, value] of Object.entries(device_selected_simulation.value)) {
      input[key] = simulationParamsInput.value[key][value];
    }
    input['经济性分析参数'] = optParamsInput.value['经济性分析参数'];
    request
      .post('/simulation_ies_h2', {
        inputdata: input,
        area: regionChoosed.value,
        mode: modeChoosed.value
      })
      .then(
        response => {
          isCalculating.value = false;
          if (!isNull(response.error)) {
            message.error('计算失败');
            return;
          }
          // window.$message.success('仿真成功');
          message.success('计算成功');

          // console.log(response.data)

          const backEndData = response.data as BackEndData;
          tableData.value.push(backEndData.table);

          // console.log(backEndData.table)

          tableColumns.value = Object.keys(backEndData.table).map(key => {
            return {
              title: key,
              key,
              width: 80,
              resizable: true,
              maxWidth: 200
            };
          });
          console.log(tableColumns.value);

          figureData.value = backEndData.figure;
          console.log(backEndData.figure)

                  envFigureData.value = backEndData.envFigure;
                  console.log(backEndData.envFigure)

                  H2FigureData.value = backEndData.H2Figure;
                  console.log(backEndData.H2Figure)

          updateFigure(dayChoiceSlider.value);
        },
        error => {
          console.log(error);
        }
      );
  }

  function optToServer() {
    isCalculating.value = true;
    const optlist = new Array(8).fill(0);
    isOptimizationGroup.value.forEach((item, index) => {
      optlist[Number(item)] = 1;
    });
    const input = {};
    for (const [key, value] of Object.entries(device_selected_opt.value)) {
      input[key] = optParamsInput.value[key][value];
    }

    input['经济性分析参数'] = optParamsInput.value['经济性分析参数'];
    request
      .post('/optimization_ies_h2', {
        inputdata: input,
        mode: modeChoosed.value,
        isOpt: optlist,
        area: regionChoosed.value,
        opt_paras: {
          select_obj: Number(items.value),
          select_slo: solverChoosed.value
        }
      })
      .then(
        response => {
          isCalculating.value = false;
          if (!isNull(response.error)) {
            message.error('计算失败');
            return;
          }
          // window.$message.success('仿真成功');
          message.success('计算成功');

          // console.log(response.data)

          const backEndData = response.data as BackEndData;
          tableData.value.push(backEndData.table);

          // console.log(backEndData.table)

          tableColumns.value = Object.keys(backEndData.table).map(key => {
            return {
              title: key,
              key,
              width: 80,
              resizable: true,
              maxWidth: 200
            };
          });
          console.log(tableColumns.value);

          figureData.value = backEndData.figure;
          console.log(backEndData.figure)
                  envFigureData.value = backEndData.envFigure;

          updateFigure();
        },
        error => {
          console.log(error);
        }
      );
  }

  // 输入框格式化
  const format = (value: number | null) => {
    if (value === null) return '';
    return value.toLocaleString('en-US');
  };
  const parse = (input: string) => {
    const nums = input.replace(/,/g, '').trim();
    if (/^\d+(\.(\d+)?)?$/.test(nums)) return Number(nums);
    return nums === '' ? null : Number.NaN;
  };

  // 导出excel
  function excelExport() {
    //  const worksheet = XLSX.utils.aoa_to_sheet(excleData);
    const worksheet = XLSX.utils.json_to_sheet(tableData.value);

    //  设置每列的列宽，10代表10个字符，注意中文占2个字符
    worksheet['!cols'] = Object.keys(tableData.value[0]).map(() => {
      return {
        wpx: 100,
        alignment: {
          wrapText: true
        }
      };
    });

    //  新建一个工作簿,创建虚拟workbook
    const workbook = XLSX.utils.book_new();
    320;
    /* 将工作表添加到工作簿,生成xlsx文件(book,sheet数据,sheet命名) */
    XLSX.utils.book_append_sheet(workbook, worksheet, 'Sheet1');

    /* 输出工作表， 由文件名决定的输出格式(book,xlsx文件名称) */
    const name = `${Date().split(' ').slice(3, 5).join('_')}_规模与经济性表.xlsx`;
    XLSX.writeFile(workbook, name);

    return 0;
  }
  </script>

  <style scoped></style>
