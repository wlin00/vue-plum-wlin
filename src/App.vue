<template>
  <main class="main">
    {{ test }}
  </main>
</template>

<script lang="ts" setup>
  import { ref } from 'vue'
  const test = ref<string>('test1')

</script>

<style lang="css" scoped>
  
</style>
