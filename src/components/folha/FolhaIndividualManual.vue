<script setup lang="ts">
import FolhaIndividualBloco from './FolhaIndividualBloco.vue'
import FolhaIndividualObservacoes from './FolhaIndividualObservacoes.vue'
import type { ManualFolha } from '@/utils/folhaIndividual'

const props = defineProps<{
  manual: ManualFolha
  salvandoItem?: string | null
  salvandoPremio?: string | null
  salvandoObservacao?: boolean
}>()

const emit = defineEmits<{
  'salvar-item': [blocoId: string, itemNum: number, data: string | null]
  'salvar-premio': [blocoId: string, data: string | null]
  'salvar-observacao': [manualId: string, texto: string]
}>()

/** Número do item em salvamento dentro do bloco (chave `blocoId:itemNum`). */
function itemSalvandoEm(blocoId: string): number | null {
  const prefixo = `${blocoId}:`
  if (!props.salvandoItem?.startsWith(prefixo)) return null
  return Number(props.salvandoItem.slice(prefixo.length))
}
</script>

<template>
  <div class="flex flex-col gap-6">
    <section
      v-for="secao in manual.secoes"
      :key="secao.id"
      class="flex flex-col gap-3"
    >
      <h3 class="text-xs font-semibold uppercase tracking-wide text-surface-500">
        {{ secao.nome }}
      </h3>

      <FolhaIndividualObservacoes
        v-if="secao.tipo === 'observacoes'"
        :texto="manual.observacoes"
        :salvando="salvandoObservacao"
        @salvar="texto => emit('salvar-observacao', manual.id, texto)"
      />

      <div
        v-else
        class="grid grid-cols-1 gap-3 lg:grid-cols-2"
      >
        <FolhaIndividualBloco
          v-for="bloco in secao.blocos"
          :key="bloco.id"
          :bloco="bloco"
          :salvando-item="itemSalvandoEm(bloco.id)"
          :salvando-premio="salvandoPremio === bloco.id"
          @salvar-item="(itemNum, data) => emit('salvar-item', bloco.id, itemNum, data)"
          @salvar-premio="data => emit('salvar-premio', bloco.id, data)"
        />
      </div>
    </section>
  </div>
</template>
