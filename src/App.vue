<template>
  <div class="wrap">
    <canvas ref="el" width="800" height="800" class="canvas"></canvas>
    <div class="action">
      <span>
        <svg class="icon" :class="{'disabled': growthRate <= 1}" @click="decreaseRate">
          <use :xlink:href="`#i-bottomArrow`"></use>
        </svg>
      </span>
      <span class="font">当前生长速率：{{ growthRate }}</span>
      <span>
        <svg class="icon" :class="{'disabled': growthRate >= 10}" @click="encreaseRate">
          <use :xlink:href="`#i-topArrow`"></use>
        </svg>
      </span>
    </div>
    <div class="action">
      <Button class="button" @click="reset">重置画布</Button>
    </div>
  
  </div>
</template>

<script lang="ts" setup>
  import { computed, onMounted, ref, nextTick } from 'vue'
  import { IPoint, IPolar } from './types/interface'
  import './iconfont'
  import Button from './components/Button.vue'
  import { useStorage } from '@vueuse/core'

  // 长度变量 todo 数据可供用户调整，并做持久化
  const WIDTH = 800, HEIGHT = 800, LENGTH = 50
  // 获取mounted中需要使用的画布ctx上下文
  const el = ref<HTMLCanvasElement>()
  const computeCtx = computed(() => el.value?.getContext('2d')!)
  let pendingTask: Function[] = [] // 当前frame回调数组
  const growthRate = ref<any>(useStorage('growthRate', 7))
  const growthToFrameNumber = computed<number>(() => Math.abs(13 - growthRate.value)) // 当前生长速率转帧数

  // 初始化
  const init = () => {
    const ctx = computeCtx.value
    // 画线颜色初始化：若要支持黑白换肤，颜色可设置为中色灰百分之50透明度，这样黑底或者白底都是灰色
    ctx.strokeStyle = '#fff'
    // 根据起点、终点绘制canvas
    const startPoint: IPoint = { x: WIDTH / 2, y: HEIGHT }
    const polar: IPolar = { // 让画线只接收极坐标的三个参数：start、length、angle
      start: startPoint,
      length: LENGTH,
      angle: -Math.PI / 2
    }
    frame(polar)
  }

  // 收集调用栈pendingTask，推送当前帧的树枝生长frame入调用堆栈
  const frame = (polar: IPolar, depth: number = 0) => {
    const endPoint = getEndPoint(polar)
    drawLineFromPolar(polar)
    const leftPolar = {
      start: endPoint,
      length: polar.length,
      angle: polar.angle - 0.3 * Math.random()
    }
    const rightPolar = {
      start: endPoint,
      length: polar.length,
      angle: polar.angle + 0.3 * Math.random()
    }
    if (depth < 4 || Math.random() < 0.4) { // 有一定几率往左生长树枝，收集当前层级的frame回调
      pendingTask.push(() => frame(leftPolar, ++depth))
    }
    if (depth < 4 || Math.random() < 0.4) { // 有一定几率往右生长树枝，收集当前层级的frame回调
      pendingTask.push(() => frame(rightPolar, ++depth))
    }
  }

  // 执行并清空当前frame调用堆栈
  const loopTask = () => {
    // 只清空执行frame的pengding调用栈
    const tasks: Function[] = []
    pendingTask = pendingTask.filter((task: Function) => {
      if (Math.random() > 0.4) {
        tasks.push(task)
        return false
      }
      return true
    })
    tasks.forEach((task: Function) => task())
  }

  // 启动一个requestAnimationFrame的按帧监听，每一帧里清空当前调用栈来绘制动画帧
  let frameCount = 0
  const run = () => {
    requestAnimationFrame(() => {
      frameCount += 1
      if (frameCount % growthToFrameNumber.value === 0) { // 控制动画每帧间隔快慢
        loopTask()
        console.log('ppp', pendingTask, 'count', frameCount)
        if (pendingTask.length === 0) {
          init()
        }
        if (frameCount > 1200) { // 可生长最大帧数
          reset()
        }
      }
      run()
    })
  }
  run() // 启动按帧数的动画

  // 根据polar极坐标，获取对应的end下标
  const getEndPoint = (polar: IPolar): IPoint => {
    return {
      x: polar.start.x + Math.cos(polar.angle) * polar.length,
      y: polar.start.y + Math.sin(polar.angle) * polar.length
    }
  }

  // 根据笛卡尔坐标画线
  const drawLineFromPoint = (startPoint: IPoint, endPoint: IPoint) => {
    const ctx = computeCtx.value
    ctx.beginPath()
    ctx.moveTo(startPoint.x, startPoint.y)
    ctx.lineTo(endPoint.x, endPoint.y)
    ctx.stroke()
  }

  // 根据极坐标，找出当前线条的起点和终点，然后再根据下标画线
  const drawLineFromPolar = (polar: IPolar) => {
    const { length, start, angle } = polar
    const end = {
      x: start.x + Math.cos(angle) * length,
      y: start.y + Math.sin(angle) * length,
    }
    drawLineFromPoint(start, end)
  }

  // 重置当前枯木生长
  const reset = async () => {
    frameCount = 0
    pendingTask = []
    await nextTick()
    el.value.width = WIDTH // 重置画布的宽/高 会重新生成画布
  }

  // 减少枯木生长速度
  const decreaseRate = () => {
    if (growthRate.value <= 1) {
      return
    }
    growthRate.value -= 1
  }

  // 增加枯木生长速度
  const encreaseRate = () => {
    if (growthRate.value >= 10) {
      return
    }
    growthRate.value += 1
  }

  onMounted(() => {
    init()
  })

</script>

<style lang="scss" scoped>
  .wrap {
    box-sizing: border-box;
    padding-top: 150px;
  }
  .action {
    margin: 20px;
    align-items: center;
    display: flex;
    width: 100%;
    justify-content: center;
    user-select: none;

  }
  .icon {
    display: inline-flex;
    font-size: 18px;
    width: 18px;
    height: 18px;
    margin: 0 30px;
    cursor: pointer;
    align-items: center;
    justify-content: center;
    &:not(.disabled):hover {
      opacity: .7;
    }
    &.disabled {
      cursor: not-allowed;
    }
  }
  .font {
    color: #fff;
    font-size: 18px;
    font-weight: bold;
  }
  .button {
    margin-left: 20px;
    background: #5e9889;
    box-sizing: border-box;
    border: 1px solid #5e9889;
    display: inline-flex;
    height: 42px;
    align-items: center;
    justify-content: center;
    padding: 0 16px;
    color: #fff;
    font-weight: bold;
    font-size: 18px;
    border-radius: 10px;
    cursor: pointer;
    &:hover {
      opacity: .7;
    }
  }
  .canvas {
    box-sizing: border-box;
    border: 1px solid grey;
  }
</style>
