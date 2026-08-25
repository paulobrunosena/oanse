<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import Button from 'primevue/button'
import Card from 'primevue/card'
import InputText from 'primevue/inputtext'
import Select from 'primevue/select'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/composables/useAuth'
import { useJogos } from '@/composables/useJogos'
import { useRole } from '@/composables/useRole'
import { useToast } from '@/composables/useToast'
import type { Database } from '@/types/database.types'

type Clube = Database['public']['Tables']['clubes']['Row']

const toast = useToast()
const { profile } = useAuth()
const { isDiretorClube } = useRole()
const { catalogo, carregarCatalogo, criarCatalogoItem, atualizarCatalogoItem, excluirCatalogoItem } = useJogos()

const clubes = ref<Clube[]>([])
const clubeSelecionado = ref<string>('')
const novoNome = ref('')
const editandoId = ref<string | null>(null)
const editandoNome = ref('')
const carregando = ref(true)

const clube = computed(() => clubes.value.find(c => c.id === clubeSelecionado.value) ?? null)

const itensDoClube = computed(() =>
  catalogo.value.filter(i => i.clube_id === clubeSelecionado.value),
)

const opcoesClubes = computed(() =>
  clubes.value.map(c => ({ label: c.nome, value: c.id })),
)

async function carregarTudo() {
  carregando.value = true
  const [rClubes] = await Promise.all([
    supabase.from('clubes').select('*').order('ordem'),
    carregarCatalogo(),
  ])
  clubes.value = rClubes.data ?? []

  const clubeId = isDiretorClube.value && profile.value?.clube_id
    ? profile.value.clube_id
    : clubes.value[0]?.id ?? ''
  clubeSelecionado.value = clubeId
  carregando.value = false
}

async function adicionar() {
  const nome = novoNome.value.trim()
  if (!nome || !clubeSelecionado.value) return
  try {
    await criarCatalogoItem(clubeSelecionado.value, nome)
    await carregarCatalogo()
    novoNome.value = ''
    toast.add({ title: 'Jogo adicionado ao catálogo', color: 'success' })
  }
  catch (e) {
    toast.add({
      title: 'Erro ao adicionar',
      description: (e as { message?: string })?.message ?? 'Tente novamente',
      color: 'error',
    })
  }
}

function iniciarEdicao(id: string, nome: string) {
  editandoId.value = id
  editandoNome.value = nome
}

async function salvarEdicao(id: string) {
  const nome = editandoNome.value.trim()
  if (!nome) return
  try {
    await atualizarCatalogoItem(id, { nome })
    await carregarCatalogo()
    editandoId.value = null
    toast.add({ title: 'Jogo atualizado', color: 'success' })
  }
  catch (e) {
    toast.add({
      title: 'Erro ao atualizar',
      description: (e as { message?: string })?.message ?? 'Tente novamente',
      color: 'error',
    })
  }
}

async function excluir(id: string, nome: string) {
  if (!window.confirm(`Excluir o jogo "${nome}" do catálogo?`)) return
  try {
    await excluirCatalogoItem(id)
    await carregarCatalogo()
    toast.add({ title: 'Jogo excluído', color: 'info' })
  }
  catch (e) {
    toast.add({
      title: 'Erro ao excluir',
      description: (e as { message?: string })?.message ?? 'Tente novamente',
      color: 'error',
    })
  }
}

onMounted(carregarTudo)
</script>

<template>
  <div class="p-4 sm:p-6 max-w-3xl mx-auto w-full">
    <div class="mb-4">
      <h1 class="text-2xl font-bold">
        Catálogo de jogos
      </h1>
      <p class="text-sm text-surface-500 mt-1">
        Cadastre os nomes dos jogos de cada clube. Eles aparecem no combo do
        registro de rodadas (nomes repetidos entre clubes não duplicam).
      </p>
    </div>

    <div
      v-if="carregando"
      class="flex justify-center py-10"
    >
      <i class="pi pi-spin pi-spinner text-2xl text-surface-400" />
    </div>

    <template v-else>
      <div class="mb-3">
        <Select
          v-model="clubeSelecionado"
          :options="opcoesClubes"
          option-label="label"
          option-value="value"
          :disabled="isDiretorClube"
          placeholder="Selecionar clube"
          class="w-full sm:w-64"
        />
      </div>

      <Card>
        <template #title>
          <div class="flex items-center justify-between gap-3">
            <span>{{ clube?.nome ?? 'Clube' }}</span>
            <span class="text-sm text-surface-500">
              {{ itensDoClube.length }} jogo(s)
            </span>
          </div>
        </template>
        <template #content>
          <div
            v-if="itensDoClube.length === 0"
            class="py-6 text-center text-surface-500 text-sm"
          >
            Nenhum jogo cadastrado para este clube ainda.
          </div>

          <ul
            v-else
            class="flex flex-col gap-2"
          >
            <li
              v-for="item in itensDoClube"
              :key="item.id"
              class="flex items-center justify-between gap-2 rounded-md border p-2"
            >
              <template v-if="editandoId === item.id">
                <InputText
                  v-model="editandoNome"
                  class="w-full"
                  size="small"
                  @keyup.enter="salvarEdicao(item.id)"
                />
                <div class="flex items-center gap-1 shrink-0">
                  <Button
                    icon="pi pi-check"
                    severity="success"
                    text
                    size="small"
                    @click="salvarEdicao(item.id)"
                  />
                  <Button
                    icon="pi pi-times"
                    severity="secondary"
                    text
                    size="small"
                    @click="editandoId = null"
                  />
                </div>
              </template>
              <template v-else>
                <span class="truncate text-sm">{{ item.nome }}</span>
                <div class="flex items-center gap-1 shrink-0">
                  <Button
                    icon="pi pi-pencil"
                    severity="secondary"
                    text
                    size="small"
                    title="Editar"
                    @click="iniciarEdicao(item.id, item.nome)"
                  />
                  <Button
                    icon="pi pi-trash"
                    severity="danger"
                    text
                    size="small"
                    title="Excluir"
                    @click="excluir(item.id, item.nome)"
                  />
                </div>
              </template>
            </li>
          </ul>

          <div class="mt-4 flex items-center gap-2">
            <InputText
              v-model="novoNome"
              placeholder="Nome do jogo (ex.: maratona)"
              class="flex-1"
              size="small"
              @keyup.enter="adicionar"
            />
            <Button
              icon="pi pi-plus"
              label="Adicionar"
              :disabled="!novoNome.trim()"
              size="small"
              @click="adicionar"
            />
          </div>
        </template>
      </Card>
    </template>
  </div>
</template>