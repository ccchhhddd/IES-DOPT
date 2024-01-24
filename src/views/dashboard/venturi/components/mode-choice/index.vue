<template>
  <n-divider title-placement="center">{{ props.title + props.description }}文丘里管压力分布仿真</n-divider>

  <!-- 第一行 模式选择与经纬度-->
  <n-grid :x-gap="16" :y-gap="16" :item-responsive="true" class="pb-15px">
    <n-grid-item span="0:24 640:24 1024:12">
      <n-card :bordered="false" class="rounded-16px shadow-sm">
        <p class="text-16px font-bold inline-block">是否有摩擦</p>
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

    <n-grid-item span="0:24 640:24 1024:12">
      <n-card :bordered="false" class="rounded-16px shadow-sm">
        <p class="text-16px font-bold inline-block">地点经纬度(待开发)</p>
        <p class="text-16px text-red inline-block">*</p>
        <n-space justify="space-between">
          <n-input-number v-model:value="longitude" class="py-4px" placeholder="0.0">
            <template #prefix>经度:</template>
          </n-input-number>
          <n-input-number v-model:value="latitude" class="py-4px" placeholder="0.0">
            <template #prefix>纬度:</template>
          </n-input-number>
        </n-space>
      </n-card>
    </n-grid-item>
  </n-grid>

  <!-- 第二行 系统图片与参数输入 -->
  <n-grid :x-gap="16" :y-gap="16" :item-responsive="true" class="pb-15px">
    <!-- 系统图片 -->
    <n-grid-item span="0:24 640:24 1024:12">
      <n-card :bordered="false" class="rounded-16px shadow-sm">
        <n-space justify="center">
          <p class="text-28px font-bold pb-12px">示意图</p>
        </n-space>
        <n-space justify="center">
          <n-image src="/venturi.png" alt="mode-choice" width="600" />
        </n-space>
        <!-- <n-space v-if='modeChoosed == 3' justify='center'>
          <n-image src="/制冷循环.png" alt="mode-choice" width="600" />
        </n-space> -->
      </n-card>
    </n-grid-item>
    <!-- 参数输入 -->
    <n-grid-item span="0:24 640:24 1024:12">
      <n-card class="rounded-16px shadow-sm">
        <n-tabs type="line" size="large" :tabs-padding="20" pane-style="padding: 20px;">
          <n-tab-pane name="仿真计算参数输入">
            <n-spin size="large" :show="isCalculating">
              <template #description>正在计算中，请稍等...</template>
              <n-collapse :accordion="true">
                <n-collapse-item
                  v-for="(val, key, ind) in simulationParamsInput"
                  :title="key"
                  :name="ind"
                  :disabled="modeChoosed == 0"
                >
                  <!-- ind代表第几个不显示，用于在模式切换时进行选择 -->
                  <n-space vertical justify="space-between" size="large" style="margin-bottom: 10px">
                    <n-input
                      v-for="(val_input, key_input, _) in (Object.fromEntries(Object.entries(val).filter(([key,_])=>key!=='流体种类')) as { [key: string]: number })"
                      v-model:value="val[key_input as keyof typeof val]"
                      :placeholder="val_input.toString()"
                      :parse="parse"
                      :format="format"
                    >
                      <template #prefix>{{ key_input }}：</template>
                    </n-input>
                    <p>流体种类：</p>
                    <n-select
                      v-model:value="val['流体种类']"
                      :options="wfOptions"
                      @update:value="(value: string, options: SelectOption)=>val['流体种类']=value"
                    />
                  </n-space>
                </n-collapse-item>
                <n-divider></n-divider>
              </n-collapse>
              <n-button size="large" type="info" strong round style="width: 100%" :on-click="simulateToServer">
                点击进行仿真计算
              </n-button>
              <n-grid :x-gap="16" :y-gap="16" :item-responsive="true"></n-grid>
            </n-spin>
          </n-tab-pane>

          //
          <!-- <n-tab-pane name='优化计算参数输入'>
          //   <n-spin size="large" :show="isCalculating">
          //     <template #description>
          //       正在计算中，请稍等......
          //     </template>
          //     <n-gradient-text :size="16">选择待优化容量参数:</n-gradient-text>
          //     <n-select multiple placeholder="选择容量优化参数" v-model:options="isOptimizationOptions"
          //       v-model:value="isOptimizationGroup" style='margin-bottom: 15px;margin-top: 5px;' />
          //     <n-collapse :accordion="true">
          //       <n-collapse-item v-for="(val, key, ind) in simulationParamsInput" :title='key' :name='ind'
          //         :disabled='(modeChoosed < 3) && (ind == 4)'>
          //         <n-space vertical justify='space-between' size='large' style='margin-bottom: 10px;'>
          //           <n-input v-for="(val_input, key_input,) in (Object.fromEntries(Object.entries(val).filter(([key,_])=>key!=='工质')) as { [key: string]: number })"
					// 					v-model:value='val[key_input as keyof typeof val]' :disabled="(modeChoosed > 3)||(modeChoosed!==ind+1)"
          //              :placeholder='val_input.toString()'
          //             :parse="parse" :format="format">
          //             <template #prefix>{{ key_input }}： </template>
          //           </n-input>
					// 					<p>工质：</p>
          //           <n-select v-model:value="val['工质']" :options="wfOptions" @update:value="(value: string, options: SelectOption)=>val['工质']=value" :disabled="(modeChoosed > 3)||(modeChoosed!==ind+1)"/>
          //         </n-space>
          //       </n-collapse-item>
          //       <n-divider></n-divider>
          //     </n-collapse>
          //     <n-button size='large' type='info' strong round style='width: 100%;'
          //       :on-click="optimizeToServer">点击进行优化计算</n-button>
          //   </n-spin>
          // </n-tab-pane> -->
        </n-tabs>
      </n-card>
    </n-grid-item>
  </n-grid>

  <n-divider title-placement="center">结果输出</n-divider>

  <n-space vertical>
    <n-card :bordered="false" class="rounded-16px shadow-sm">
      <n-space justify="center">
        <p class="text-24px font-bold pb-12px">文丘里管压力分布图</p>
        <!-- <n-switch v-model:value="dayOrWeek" size="large" class='pt-15px' @update:value="updateSwich">
          <template #checked> 周数据图 </template>
          <template #unchecked> 日数据图 </template>
        </n-switch> -->
      </n-space>
      <!-- <n-slider v-if="!dayOrWeek" v-model:value="dayChoiceSlider" :step="1" :max="365" :min="1"
        :on-update:value="updateFigure" />
      <n-slider v-else v-model:value="dayChoiceSlider" :step="1" :max="52" :min="1" :on-update:value="updateFigure" /> -->
      <div ref="lineRef" class="w-full h-640px" style="margin-top: 15px"></div>
    </n-card>
  </n-space>
</template>

<script setup lang="ts">
import type { Ref } from 'vue';
import { ref, onMounted } from 'vue';
import type { SelectOption } from 'naive-ui';
import { useMessage } from 'naive-ui';
import * as XLSX from 'xlsx';
import { useMounted } from '@vueuse/core';
import { type ECOption, useEcharts } from '@/composables';
// import { result, toUpper } from 'lodash-es';
// import { number } from 'echarts';
import { request } from '@/service/request/index';
import { isNull } from '~/src/utils';

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

const modeChoosed = ref<number>(1); //
// 经纬度数据
const longitude = ref<number>(0.0);
const latitude = ref<number>(0.0);
// const dayOrWeek = ref<boolean>(false);

const isCalculating = ref<boolean>(false);

// 滑动条数据
// const dayChoiceSlider = ref<number>(1);

// 模式选择选项
const modeOptions = [
  {
    label: '是',
    value: 1
  },
  {
    label: '否',
    value: 2
  }
];

// 工质选择
const wfOptions = [
  {
    label: 'Water',
    value: 'Water'
  },
  {
    label: 'Air',
    value: 'Air'
  }
];

// 检测到模式选择变化时，打印出来
//  watch(simulateOrOptimizeSwitch, (newValue, oldValue) => {
//    console.log('modeChoosed changed from', oldValue, 'to', newValue)
//  })

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
        pixelRatio: 4
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
        show: true, // 是否显示该工具。
        title: '数据视图',
        readOnly: false, // 是否不可编辑（只读）
        lang: ['数据视图', '关闭', '刷新'], // 数据视图上有三个话术，默认是['数据视图', '关闭', '刷新']
        backgroundColor: '#fff', // 数据视图浮层背景色。
        textareaColor: '#fff', // 数据视图浮层文本输入区背景色
        textareaBorderColor: '#333', // 数据视图浮层文本输入区边框颜色
        textColor: '#000', // 文本颜色。
        buttonColor: '#c23531', // 按钮颜色。
        buttonTextColor: '#fff' // 按钮文本颜色。
      }
    }
  },
  tooltip: {
    trigger: 'axis',
    axisPointer: {
      type: 'cross',
      label: {
        backgroundColor: '#6a7986'
      }
    }
  },
  legend: {
    data: []
  },
  grid: {
    left: '3%',
    right: '4%',
    bottom: '3%',
    containLabel: true
  },
  xAxis: {
    type: 'value',
    name: '位置(m)',
    axisLabel: {
      formatter: '{value} m'
    }
  },
  yAxis: {
    type: 'value',
    name: '压力(mH2O)',
    axisPointer: {
      snap: true
    },
    // axisLine: { onZero: false },
    axisLabel: {
      formatter: '{value} mH2O'
    }
  },
  series: [
    {
      name: '换热器',
      type: 'line',
      smooth: true,
      // stack: 'Total',
      // areaStyle: {},
      emphasis: {
        focus: 'series'
      }

      //   data: [
      //     // 维度X   维度Y   其他维度 ...
      //     [  5.4,    4.5  ],
      // 		[  3.4,    4.5, ],
      //     [  7.2,    2.3, ],
      //     [  10.8,   4,   ],
      // 		[  9.8,   8.5,  ],
      // 		[  9.8,   9.5,  ],
      // 		[  8.8,   4.5,  ],
      // 		[  5.4,    4.5  ]
      // ]
    }
  ]
}) as Ref<ECOption>;
const { domRef: lineRef } = useEcharts(lineOptions);

// 表格数据类型
type TableData = {
  [key: string]: number;
};

// 图表数据类型
type FigureData = {
  xyAxis: Array<number>;
  xyAxis1: Array<number>;
};

// 后端接受数据类型
type BackEndData = {
  table: TableData;
  figure: FigureData;
};

// 仿真参数数据类型
type SimulationParams = {
  仿真参数: {
    '流量(m^3/s)': number;
    流体种类: string;
  };
};

const simulationParamsInput = ref<SimulationParams>({
  仿真参数: {
    '流量(m^3/s)': 0.1,
    流体种类: 'Water'
  }
});

// 监测isOptimizationGroup的值是否改变
// watch(isOptimizationGroup, (val) => {
//   console.log(val)
// })

const tableData = ref<TableData[]>([]); // 表格数据
const figureData = ref<FigureData>({ xyAxis: [], xyAxis1: [] }); // 图数据

// 模式选择数据更新
function updateModeSelectData(value: number, options: SelectOption) {
  if (value == 1) {
    // isOptimizationOptions.value[4].disabled = true;
  } else {
    // isOptimizationOptions.value[4].disabled = false;
  }
  tableData.value = [];
}

// 工质选择数据更新
// function updatewfSelectData(value: number, options: SelectOption) {
//   if (value == 1) {
//     simulationParamsInput
//   }
// 	else if(value == 2){

// 	}
//   tableData.value = [];
// }

// 更新表格数据
const updateFigure = () => {
  // dayChoiceSlider.value = dayValue;
  // let dataRange = dayOrWeek.value ? 24 * 7 : 24;

  // 图1画面
  lineOptions.value.yAxis = {
    type: 'value',
    name: '压力(mH2O)',
    axisPointer: {
      snap: true
    },
    axisLabel: {
      formatter: '{value} mH2O'
    }
  };
  lineOptions.value.xAxis = {
    type: 'value',
    name: '位置(m)',
    axisLabel: {
      formatter: '{value} m'
    }
  };

  lineOptions.value.series = {
    name: '文丘里管',
    type: 'line',
    smooth: true,
    // stack: 'Total',
    // areaStyle: {},
    emphasis: {
      focus: 'series'
    },
    data: figureData.value.xyAxis
  };
  lineOptions.value.legend = {
    data: []
  };
};

// const updateSwich = (value: boolean) => {
//   dayOrWeek.value = value;
//   updateFigure(dayChoiceSlider.value);
// }

const message = useMessage();

// 从后端获取数据
function simulateToServer() {
  isCalculating.value = true;
  request
    .post('/simulation_2', {
      inputdata: simulationParamsInput.value,
      mode: modeChoosed.value
    })
    .then(
      response => {
        isCalculating.value = false;
        if (!isNull(response.error)) {
          console.log(response.error);
          message.error('计算失败');
          return;
        }
        // window.$message.success('仿真成功');
        message.success('计算成功');

        const backEndData = response.data as BackEndData;

        console.log(response.data);
        // console.log(backEndData.table);
        // console.log(tableColumns.value);
        figureData.value = backEndData.figure;
        // console.log(figureData)
        updateFigure();
      },
      error => {
        console.log(error);
      }
    );
}

// function optimizeToServer() {
//   isCalculating.value = true;
//   let isOptimizationList = Object.values(isOptimizationOptions.value).map((val) => {
//     return isOptimizationGroup.value.indexOf(val.value) > -1 ? 1 : 0;
//   });
//   request.post('/optimization', {
//     "inputdata": Object.assign({}, simulationParamsInput.value, { "优化时长": optimizationTime.value }),
//     "mode": modeChoosed.value,
//     "isopt": isOptimizationList
//   }).then((response) => {
//     isCalculating.value = false;
//     if (!isNull(response.error)) {
//       message.error('计算失败');
//       return;
//     }
//     message.success('计算成功');
//     let backEndData = response.data as BackEndData;
//     tableData.value.push(backEndData.table);
//     tableColumns.value = Object.keys(backEndData.table).map((key) => {
//       return {
//         title: key,
//         key: key,
//         width: 80,
//         resizable: true,
//         maxWidth: 200,
//       }
//     });
//     figureData.value = backEndData.figure;
//     // updateFigure(dayChoiceSlider.value);
//   }, (error) => {
//     console.log(error);
//   });
// }

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
</script>

<style scoped></style>
