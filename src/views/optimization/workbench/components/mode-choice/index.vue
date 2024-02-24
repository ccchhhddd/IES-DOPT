<template>
  <n-divider title-placement='center'>{{ props.title + props.description }}制氢综合能源</n-divider>

  <!-- 第一行 模式选择与经纬度-->
  <n-grid :x-gap='16' :y-gap='16' :item-responsive='true' class='pb-15px'>

    <n-grid-item span='0:24 640:24 1024:12'>
      <n-card :bordered='false' class='rounded-16px shadow-sm'>
        <p class='text-16px font-bold inline-block '>模式选择</p>
        <p class='text-16px text-red inline-block'> *</p>
        <!-- 在文字后面显示下拉框 -->
        <n-select v-model:value='modeChoosed' :options='modeOptions' style='' class='py-5px'
          @update:value="updateModeSelectData" />
      </n-card>
    </n-grid-item>

    <n-grid-item span='0:24 640:24 1024:12'>
      <n-card :bordered='false' class='rounded-16px shadow-sm'>
        <p class='text-16px font-bold inline-block '>地点经纬度(待开发)</p>
        <p class='text-16px text-red inline-block'> *</p>
        <n-space justify='space-between'>
          <n-input-number v-model:value='longitude' class='py-5px ' placeholder='0.0'>
            <template #prefix>经度</template>
          </n-input-number>
          <n-input-number v-model:value='latitude' class='py-5px' placeholder='0.0'>
            <template #prefix>纬度<!-- prefix: 前缀 --></template>
          </n-input-number>
        </n-space>
      </n-card>
    </n-grid-item>

  </n-grid>

  <!-- 第二行 系统图片与参数输入 -->
  <n-grid :x-gap='16' :y-gap='16' :item-responsive='true' class='pb-15px'>
    <!-- 系统图片 -->
    <n-grid-item span='0:24 640:24 1024:12'>
      <n-card :bordered='false' class='rounded-16px shadow-sm'>
        <n-space justify='center'>
          <p class='text-28px font-bold pb-12px'>系统图</p>
        </n-space>
        <n-space v-if='modeChoosed == 1' justify='center'>
          <n-image src="/离网制氢系统结构图.png" alt="mode-choice" width="600" />
        </n-space>
      </n-card>
    </n-grid-item>
    <!-- 参数输入 -->
    <n-grid-item span='0:24 640:24 1024:12'>
      <n-card class='rounded-16px shadow-sm'>
        <n-tabs type='line' size='large' :tabs-padding='20' pane-style='padding: 20px;'>
          <n-tab-pane name='仿真计算参数输入'>
            <n-spin size="large" :show="isCalculating">
              <template #description>
                正在计算中，请稍等...
              </template>
              <n-collapse :accordion="true">
                <n-collapse-item v-for="(val, key, ind) in simulationParamsInput" :title='key' :name='ind'>
                  <!-- 只有离网开启储能参数输入 -->
                  <n-space vertical justify='space-between' size='large' style='margin-bottom: 10px;'>
                    <n-input-number v-for="(val_input, key_input, _) in (val as { [key: string]: number; })"
                      v-model:value='val[key_input as keyof typeof val]'
                      :placeholder='val_input.toString()' :parse="parse" :format="format">
                      <template #prefix>{{ key_input }}： </template>
                    </n-input-number>
                  </n-space>
                </n-collapse-item>
                <n-divider></n-divider>
              </n-collapse>
              <n-button size='large' type='info' strong round style='width: 100%;' :on-click="simulateToServer">
                点击进行仿真计算
              </n-button>
            </n-spin>
          </n-tab-pane>

          <!-- <n-tab-pane name='优化计算参数输入'>
            <n-spin size="large" :show="isCalculating">
              <template #description>
                正在计算中，请稍等......
              </template>
              <n-gradient-text :size="16">选择待优化容量参数:</n-gradient-text>
              <n-select multiple placeholder="选择容量优化参数" v-model:options="isOptimizationOptions"
                v-model:value="isOptimizationGroup" style='margin-bottom: 15px;margin-top: 5px;' />
              <n-collapse :accordion="true">
                <n-collapse-item v-for="(val, key, ind) in simulationParamsInput" :title='key' :name='ind'
                  :disabled='(modeChoosed < 3) && (ind == 4)'>
                  <n-space vertical justify='space-between' size='large' style='margin-bottom: 10px;'>
                    <n-input-number v-for="(val_input, key_input, ind_input) in (val as { [key: string]: number; })"
                      v-model:value='val[key_input as keyof typeof val]'
                      :disabled="(modeChoosed >= 2 && key_input == '卖电电价（￥/kwh）') || (modeChoosed == 3 && key_input == '买电电价（￥/kwh）') ||
                        (ind <= 4 && ind_input == 0 && isOptimizationGroup.indexOf(isOptimizationOptions[ind].value) >= 0)" :placeholder='val_input.toString()'
                      :parse="parse" :format="format">
                      <template #prefix>{{ key_input }}： </template>
                    </n-input-number>

                  </n-space>
                </n-collapse-item>
                <n-divider></n-divider>
              </n-collapse>
              <n-button size='large' type='info' strong round style='width: 100%;'
                :on-click="optimizeToServer">点击进行优化计算</n-button>
            </n-spin>
          </n-tab-pane> -->

        </n-tabs>
      </n-card>
    </n-grid-item>
  </n-grid>


  <n-divider title-placement='center'>
    结果输出
  </n-divider>
  <n-space vertical>
    <n-card :bordered='false' class='rounded-16px shadow-sm'>
      <n-space justify='center'>
                <p class='text-24px font-bold pb-12px'>系统储氢M-T图</p>
      </n-space>
      <!-- <n-slider v-if="!dayOrWeek" v-model:value="dayChoiceSlider" :step="1" :max="365" :min="1"
        :on-update:value="updateFigure" />
      <n-slider v-else v-model:value="dayChoiceSlider" :step="1" :max="52" :min="1" :on-update:value="updateFigure" /> -->
      <div ref='lineRef' class='w-full h-640px' style="margin-top: 15px;"></div>
    </n-card>
    <n-card :bordered='false' class='rounded-16px shadow-sm'>
      <n-space justify='center'>
        <p class='text-24px font-bold pb-12px'>规模与经济性表</p>
        <n-button type='success' round :on-click='excelExport' style='margin-top: 3px;'>{{ tableData.length
        }}条数据，导出Excel表格</n-button>
      </n-space>
      <n-data-table :columns="tableColumns" :data='tableData' :pagination='{ pageSize: 10 }' :single-line='false' />
    </n-card>
  </n-space>
</template>

<script setup lang='ts'>
import { ref, Ref } from 'vue';
// import { watch } from 'vue';
import { type ECOption, useEcharts } from '@/composables';
import * as XLSX from 'xlsx';
import { useMessage, SelectOption } from 'naive-ui'
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
  },
});

const modeChoosed = ref<number>(1); //  1: 离网制氢模式
// 经纬度数据
const longitude = ref<number>(0.0);
const latitude = ref<number>(0.0);
const dayOrWeek = ref<boolean>(false);

const isCalculating = ref<boolean>(false);
// 滑动条数据
const dayChoiceSlider = ref<number>(1);

// 模式选择选项
const modeOptions = [
  {
    label: '离网制氢模式',
    value: 1
  }];

//  检测到模式选择变化时，打印出来
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
      name: '能量',
      axisLabel: {
        formatter: '{value} kW'
      }
    }
  ],
  series: [
    {
      name: '下载量',
      type: 'line',
      smooth: true,
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

// 表格数据类型
type TableData = {
  [key: string]: number
}

// 图表数据类型
type FigureData = {
  xyAxis: Array<number>;
}

// 后端接受数据类型
type BackEndData = {
  table: TableData
  figure: FigureData
}

// 仿真参数数据类型
type SimulationParams = {
  "风力发电参数": {
    "总装机容量(kW)": number,
		"单机容量(kW)": number,
    "机组数量": number,
    "风轮传动效率": number,
    "发电机效率": number,
    "使用年限(年)": number,
    "初始成本(元/kW)": number,
    "年运维成本(元/kW)": number,
    "更换成本(元/kW)": number
  },
  "光伏发电参数": {
    "总装机容量(kW)": number,
    "单机容量(kW)": number,
    "机组数量": number,
    "光伏板面积(m2)": number,
    "光伏板吸收率": number,
    "使用年限(年)": number,
    "初始成本(元/kW)": number,
		"年运维成本(元/kW)": number,
		"更换成本(元/kW)": number,
  },
  "燃气轮机发电参数": {
    "总装机容量(kW)": number,
    "最小出力效率": number,
    "出力调整系数": number,
    "发电效率": number,
    "低位发热值(MJ/Nm³)": number,
    "使用年限(年)": number,
    "初始成本(元/kW)": number,
		"年运维成本(元/kW)": number,
		"更换成本(元/kW)": number,
  },
  "整流器参数": {
    "装机额定功率(kW)": number,
    "整流器综合效率": number,
    "使用年限(年)": number,
    "初始成本(元/kg)": number,
    "年运维成本(元/kg)": number,
    "更换成本(元/kg)": number,
  },
  "压缩空气储能参数": {
    "装机额定功率(kW)": number,
    "充电效率": number,
    "使用年限(年)": number,
    "初始成本(元/kW)": number,
    "年运维成本(元/kW)": number,
    "更换成本(元/kW)": number,
  },
  "电解槽参数": {
    "额定功率(kW)": number,
    "氢燃料低位发热值(MJ/kg)": number,
    "负载最小效率": number,
    "使用年限(年)": number,
    "初始成本(元/kW)": number,
    "年运维成本(元/kW)": number,
    "更换成本(元/kW)": number,
  },
	"氢气压缩机参数": {
    "装机容量(kg)": number,
    "单位耗电量(kWh/kg)": number,
    "使用年限(年)": number,
    "初始成本(元/kg)": number,
    "年运维成本(元/kg)": number,
    "更换成本(元/kg)": number,
  },
	"储氢罐参数": {
    "装机容量(kg)": number,
    "使用年限(年)": number,
    "初始成本(元/kg)": number,
    "年运维成本(元/kg)": number,
    "更换成本(元/kg)": number,
  },
	"经济性分析参数": {
    "运行天数": number,
    "系统设计寿命(年)": number,
    "氢气生产成本(元/kg)": number,
    "氢气销售价格(元/kg)": number,
    "天然气价格(元/Nm³)": number,
  },
}

const simulationParamsInput = ref<SimulationParams>({
  "风力发电参数": {
    "总装机容量(kW)": 4e6,
		"单机容量(kW)": 1.0,
    "机组数量": 1,
    "风轮传动效率": 0.96,
    "发电机效率": 0.93,
    "使用年限(年)": 20,
    "初始成本(元/kW)": 4800,
    "年运维成本(元/kW)": 720,
    "更换成本(元/kW)": 4800
  },
  "光伏发电参数": {
    "总装机容量(kW)": 1e7,
    "单机容量(kW)": 1.0,
    "机组数量": 1,
    "光伏板面积(m2)": 3.1,
    "光伏板吸收率": 0.9,
    "使用年限(年)": 20,
    "初始成本(元/kW)": 3800,
		"年运维成本(元/kW)": 190,
		"更换成本(元/kW)": 3800,
  },
  "燃气轮机发电参数": {
    "总装机容量(kW)": 4e6,
    "最小出力效率": 0.2,
    "出力调整系数": 0.05,
    "发电效率": 0.6,
    "低位发热值(MJ/Nm³)": 34.94,
    "使用年限(年)": 20,
    "初始成本(元/kW)": 4800,
		"年运维成本(元/kW)": 160,
		"更换成本(元/kW)": 4800,
  },
  "整流器参数": {
    "装机额定功率(kW)": 15000,
    "整流器综合效率": 0.9,
    "使用年限(年)": 20,
    "初始成本(元/kg)": 2300,
    "年运维成本(元/kg)": 46,
    "更换成本(元/kg)": 2300,
  },
  "压缩空气储能参数": {
    "装机额定功率(kW)": 15000,
    "充电效率": 0.6,
    "使用年限(年)": 15,
    "初始成本(元/kW)": 3800,
    "年运维成本(元/kW)": 190,
    "更换成本(元/kW)": 3800,
  },
  "电解槽参数": {
    "额定功率(kW)": 5e5,
    "氢燃料低位发热值(MJ/kg)": 241,
    "负载最小效率": 0.0,
    "使用年限(年)": 10,
    "初始成本(元/kW)": 2000,
    "年运维成本(元/kW)": 100,
    "更换成本(元/kW)": 2000,
  },
	"氢气压缩机参数": {
    "装机容量(kg)": 5e5,
    "单位耗电量(kWh/kg)": 1.0,
    "使用年限(年)": 20,
    "初始成本(元/kg)": 2300,
    "年运维成本(元/kg)": 46,
    "更换成本(元/kg)": 2300,
  },
	"储氢罐参数": {
    "装机容量(kg)": 5e5,
    "使用年限(年)": 20,
    "初始成本(元/kg)": 2300,
    "年运维成本(元/kg)": 46,
    "更换成本(元/kg)": 2300,
  },
	"经济性分析参数": {
    "运行天数": 700,
    "系统设计寿命(年)": 20,
    "氢气生产成本(元/kg)": 0.021,
    "氢气销售价格(元/kg)": 25.58,
    "天然气价格(元/Nm³)": 1.7,
  },
});

const isOptimizationGroup = ref<Array<number>>([2])
const optimizationTime = ref<number>(1)
const isOptimizationOptions = ref([
  {
    label: '光伏容量',
    value: 0
  },
  {
    label: '风电容量',
    value: 1
  },
  {
    label: "电解容量",
    value: 2
  },
  {
    label: '储氢容量',
    value: 3,
    disabled: true
  },
  {
    label: '储能容量',
    value: 4,
    disabled: true
  }
])

// 监测isOptimizationGroup的值是否改变
// watch(isOptimizationGroup, (val) => {
//   console.log(val)
// })

const tableColumns = ref<Array<{ title: string, key: string }>>([]);
const tableData = ref<TableData[]>([]) // 表格数据
const figureData = ref<FigureData>({ xyAxis: [] }) // 图数据

// 模式选择数据更新
function updateModeSelectData(value: number, options: SelectOption) {
  if (value == 1) {
    isOptimizationOptions.value[4].disabled = true;
  }
  else {
    isOptimizationOptions.value[4].disabled = false;
  };
  tableData.value = [];
}



// 更新表格数据
const updateFigure = () => {
  lineOptions.value.xAxis = {
    type: 'value',
    name: '小时数',
    axisLabel: {
      formatter: '{value} h'
    }
  };
	lineOptions.value.yAxis = {
    type: 'value',
    name: '储氢量',
    axisPointer: {
      snap: true
    },
    axisLabel: {
      formatter: '{value} kg'
    }
  };
  lineOptions.value.legend = {
    orient: 'horizontal',
    right: 'center'
  };
	let label;
  switch (modeChoosed.value) {
    case 1:
      label = '储氢量';
      break;
  }

  lineOptions.value.series = {
    name: label,
    type: 'line',
    smooth: true,
    emphasis: {
      focus: 'series'
    },
    data: figureData.value.xyAxis
  };
}


const message = useMessage();

// 从后端获取数据
function simulateToServer() {
  isCalculating.value = true;
  request.post('/simulation_ies_h2', {
    "inputdata": simulationParamsInput.value,
    "mode": modeChoosed.value
  }).then((response) => {
    isCalculating.value = false;
    if (!isNull(response.error)) {
      message.error('计算失败');
      return;
    }
    // window.$message.success('仿真成功');
    message.success('计算成功');

		// console.log(response.data)

    let backEndData = response.data as BackEndData;
    tableData.value.push(backEndData.table);

		// console.log(backEndData.table)

    tableColumns.value = Object.keys(backEndData.table).map((key) => {
      return {
        title: key,
        key: key,
        width: 80,
        resizable: true,
        maxWidth: 200,
      }
    });
		console.log(tableColumns.value)

    figureData.value = backEndData.figure;
		// console.log(backEndData.figure)

    updateFigure();
  }, (error) => {
    console.log(error);
  });
};
function optimizeToServer() {
  isCalculating.value = true;
  let isOptimizationList = Object.values(isOptimizationOptions.value).map((val) => {
    return isOptimizationGroup.value.indexOf(val.value) > -1 ? 1 : 0;
  });
  request.post('/optimization', {
    "inputdata": Object.assign({}, simulationParamsInput.value, { "优化时长": optimizationTime.value }),
    "mode": modeChoosed.value,
    "isopt": isOptimizationList
  }).then((response) => {
    isCalculating.value = false;
    if (!isNull(response.error)) {
      message.error('计算失败');
      return;
    }
    message.success('计算成功');
		// console.log(response.data)
    let backEndData = response.data as BackEndData;
    tableData.value.push(backEndData.table);

		// console.log(backEndData.table)
		// console.log(tableColumns.value)
    tableColumns.value = Object.keys(backEndData.table).map((key) => {
      return {
        title: key,
        key: key,
        width: 80,
        resizable: true,
        maxWidth: 200,
      }
    });

    figureData.value = backEndData.figure;
    updateFigure(dayChoiceSlider.value);
  }, (error) => {
    console.log(error);
  });
}

// 输入框格式化
const format = (value: number | null) => {
  if (value === null) return ''
  return value.toLocaleString('en-US')
};
const parse = (input: string) => {
  const nums = input.replace(/,/g, '').trim()
  if (/^\d+(\.(\d+)?)?$/.test(nums)) return Number(nums)
  return nums === '' ? null : Number.NaN
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
    }
  });

  //  新建一个工作簿,创建虚拟workbook
  const workbook = XLSX.utils.book_new();
320
  /* 将工作表添加到工作簿,生成xlsx文件(book,sheet数据,sheet命名)*/
  XLSX.utils.book_append_sheet(workbook, worksheet, 'Sheet1');

  /* 输出工作表， 由文件名决定的输出格式(book,xlsx文件名称)*/
  let name = Date().split(" ").slice(3, 5).join("_") + '_规模与经济性表.xlsx';
  XLSX.writeFile(workbook, name);

  return 0;
};

</script>

<style scoped></style>
