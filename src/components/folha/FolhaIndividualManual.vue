<script setup lang="ts">
import { ref } from 'vue'
import FolhaIndividualBloco from './FolhaIndividualBloco.vue'
import FolhaIndividualObservacoes from './FolhaIndividualObservacoes.vue'
import { secaoItensConcluidos, secaoTotalItens, type ManualFolha } from '@/utils/folhaIndividual'

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

/** Seções abertas; inicia com a primeira seção do manual expandida. */
const abertas = ref<string[]>(props.manual.secoes.length ? [props.manual.secoes[0]!.id] : [])

/** Número do item em salvamento dentro do bloco (chave `blocoId:itemNum`). */
function itemSalvandoEm(blocoId: string): number | null {
  const prefixo = `${blocoId}:`
  if (!props.salvandoItem?.startsWith(prefixo)) return null
  return Number(props.salvandoItem.slice(prefixo.length))
}
</script>

<template>
  <Accordion
    v-model:value="abertas"
    multiple
    class="flex flex-col gap-3"
  >
    <AccordionPanel
      v-for="secao in manual.secoes"
      :key="secao.id"
      :value="secao.id"
    >
      <AccordionHeader>
        <span class="flex items-center gap-2">
          <span>{{ secao.nome }}</span>
          <span
            v-if="secao.tipo === 'itens'"
            class="secao-contagem text-xs text-surface-500"
          >
            {{ secaoItensConcluidos(secao) }}/{{ secaoTotalItens(secao) }}
          </span>
        </span>
      </AccordionHeader>
      <AccordionContent>
        <div class="flex flex-col gap-3">
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
        </div>
      </AccordionContent>
    </AccordionPanel>
  </Accordion>
</template>
