<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import Avatar from 'primevue/avatar'
import Button from 'primevue/button'
import Card from 'primevue/card'
import Select from 'primevue/select'
import Tag from 'primevue/tag'
import { useAuth } from '@/composables/useAuth'
import { useEncontro } from '@/composables/useEncontro'
import { useRemanejamentos, type TurmaRemanejamento } from '@/composables/useRemanejamentos'
import { useToast } from '@/composables/useToast'

const { profile } = useAuth()
const { user } = useAuth()
const toast = useToast()
const { encontro, carregando: carregandoEncontro, carregar: carregarEncontro } = useEncontro()
const {
  turmas, lideres, carregando: carregandoRem,
  carregar, remanejamentoDe, salvar, remover,
} = useRemanejamentos()

const carregando = ref(true)
const processandoId = ref<string | null>(null)

const selecoes = reactive<Record<string, string>>({})

const dataFormatada = computed(() => {
  if (!encontro.value) return ''
  return new Date(`${encontro.value.data}T00:00:00`).toLocaleDateString('pt-BR', {
    weekday: 'long', day: 'numeric', month: 'long',
  })
})

async function carregarTudo() {
  carregando.value = true
  await carregarEncontro()
  if (profile.value?.clube_id && encontro.value) {
    await carregar(profile.value.clube_id, encontro.value.id)
    for (const t of turmas.value) {
      if (!(t.id in selecoes)) {
        selecoes[t.id] = remanejamentoDe(t.id)?.lider_substituto_id ?? ''
      }
    }
  }
  carregando.value = false
}

function opcoesSubstituto(turmaId: string, liderTitularId: string) {
  return lideres.value
    .filter(l => l.id !== liderTitularId)
    .map(l => ({ label: l.nome, value: l.id }))
}

function substitutoNome(turmaId: string): string | null {
  const rem = remanejamentoDe(turmaId)
  if (!rem) return null
  return lideres.value.find(l => l.id === rem.lider_substituto_id)?.nome ?? null
}

async function aplicar(t: TurmaRemanejamento) {
  const substitutoId = selecoes[t.id]
  if (!substitutoId) {
    toast.add({ title: 'Selecione um substituto', color: 'error' })
    return
  }
  if (!encontro.value || !user.value?.sub) return
  processandoId.value = t.id
  try {
    await salvar(encontro.value.id, t, substitutoId, user.value.sub)
    toast.add({ title: 'Remanejamento salvo', color: 'success' })
  }
  catch (e) {
    toast.add({
      title: 'Erro ao salvar remanejamento',
      description: (e as { message?: string })?.message ?? 'Tente novamente',
      color: 'error',
    })
  }
  finally {
    processandoId.value = null
  }
}

async function removerRemanejamento(t: TurmaRemanejamento) {
  if (!encontro.value) return
  processandoId.value = t.id
  try {
    await remover(t.id)
    selecoes[t.id] = ''
    toast.add({ title: 'Remanejamento removido', color: 'success' })
  }
  catch (e) {
    toast.add({
      title: 'Erro ao remover remanejamento',
      description: (e as { message?: string })?.message ?? 'Tente novamente',
      color: 'error',
    })
  }
  finally {
    processandoId.value = null
  }
}

onMounted(carregarTudo)
</script>

<template>
  <div class="p-4 sm:p-6 max-w-3xl mx-auto w-full">
    <div class="flex items-center justify-between mb-4">
      <div>
        <h1 class="text-2xl font-bold">
          Remanejamentos
        </h1>
        <p
          v-if="dataFormatada"
          class="text-sm text-surface-500 capitalize"
        >
          {{ dataFormatada }}
        </p>
      </div>
    </div>

    <div
      v-if="carregando || carregandoEncontro || carregandoRem"
      class="flex justify-center py-10"
    >
      <i class="pi pi-spin pi-spinner text-2xl text-surface-400" />
    </div>

    <Card
      v-else-if="!profile?.clube_id"
      class="text-center py-6"
    >
      <template #content>
        <p class="text-surface-500">
          Você não está vinculado a um clube. Fale com o Diretor Geral.
        </p>
      </template>
    </Card>

    <template v-else>
      <p
        v-if="lideres.length === 0"
        class="text-sm text-surface-500 mb-4"
      >
        Nenhum líder disponível no seu clube para assumir substituições.
      </p>

      <div
        v-if="turmas.length === 0"
        class="text-center py-8 text-surface-500"
      >
        Nenhuma turma ativa no seu clube.
      </div>

      <div class="flex flex-col gap-3">
        <div
          v-for="t in turmas"
          :key="t.id"
          class="rounded-lg border p-4"
        >
          <div class="flex items-center justify-between gap-3 mb-3">
            <div class="flex items-center gap-3 min-w-0">
              <Avatar
                :label="(t.lider_nome ?? '?').charAt(0).toUpperCase()"
                size="small"
              />
              <div class="min-w-0">
                <p class="font-medium truncate">
                  {{ t.nome }}
                </p>
                <p class="text-xs text-surface-500 truncate">
                  Titular: {{ t.lider_nome ?? '—' }}
                </p>
              </div>
            </div>
            <Tag
              v-if="substitutoNome(t.id)"
              :value="`Substituto: ${substitutoNome(t.id)}`"
              severity="warning"
            />
          </div>

          <div class="flex items-end gap-2">
            <div class="flex-1">
              <Select
                v-model="selecoes[t.id]"
                :options="opcoesSubstituto(t.id, t.lider_id)"
                option-label="label"
                option-value="value"
                :disabled="lideres.length <= 1"
                placeholder="Escolher substituto"
                class="w-full"
              />
            </div>
            <Button
              icon="pi pi-user-check"
              label="Aplicar"
              :loading="processandoId === t.id"
              @click="aplicar(t)"
            />
            <Button
              v-if="remanejamentoDe(t.id)"
              icon="pi pi-trash"
              severity="danger"
              text
              aria-label="Remover remanejamento"
              @click="removerRemanejamento(t)"
            />
          </div>
        </div>
      </div>

      <p class="text-xs text-surface-500 mt-4">
        O substituto passa a ver e lançar chamada e folha da turma apenas no encontro deste sábado.
      </p>
    </template>
  </div>
</template>
