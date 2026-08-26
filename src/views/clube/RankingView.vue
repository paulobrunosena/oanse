<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import Card from 'primevue/card'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/composables/useAuth'
import { useEncontro } from '@/composables/useEncontro'
import { ordenarGeral, useRanking, type LinhaRanking } from '@/composables/useRanking'
import EncontroSeletor from '@/components/encontro/EncontroSeletor.vue'

const { profile } = useAuth()
const { encontro, encontros, carregando: carregandoEncontro, carregar: carregarEncontro, selecionar } = useEncontro()
const { linhas, carregando, carregar } = useRanking()

const clubes = ref<{ id: string, nome: string }[]>([])
const carregandoInicial = ref(true)

const clubeDoPerfil = computed(() => clubes.value.find(c => c.id === profile.value?.clube_id)?.nome)

const secoes = computed(() => {
  const mapa = new Map<string, LinhaRanking[]>()
  for (const l of linhas.value) {
    if (!mapa.has(l.clube_nome)) mapa.set(l.clube_nome, [])
    mapa.get(l.clube_nome)!.push(l)
  }
  let lista = [...mapa.entries()].map(([nome, l]) => ({ nome, linhas: l }))
  if (profile.value?.role === 'diretor_clube' && clubeDoPerfil.value) {
    lista = lista.filter(s => s.nome === clubeDoPerfil.value)
  }
  return lista
})

const geral = computed(() => ordenarGeral(linhas.value))

const dataFormatada = computed(() => {
  if (!encontro.value) return ''
  return new Date(`${encontro.value.data}T00:00:00`).toLocaleDateString('pt-BR', {
    weekday: 'long', day: 'numeric', month: 'long',
  })
})

function medalha(posicao: number): string | null {
  if (posicao === 1) return '🥇'
  if (posicao === 2) return '🥈'
  if (posicao === 3) return '🥉'
  return null
}

function classePosicao(posicao: number): string {
  if (posicao === 1) return 'text-amber-500'
  if (posicao === 2) return 'text-slate-400'
  if (posicao === 3) return 'text-orange-400'
  return 'text-surface-400'
}

async function carregarTudo() {
  carregandoInicial.value = true
  const { data } = await supabase.from('clubes').select('id, nome').order('ordem')
  clubes.value = data ?? []
  await carregarEncontro()
  if (encontro.value) await carregar(encontro.value.id)
  carregandoInicial.value = false
}

async function aoSelecionarEncontro(id: string) {
  selecionar(id)
  if (encontro.value) await carregar(encontro.value.id)
}

onMounted(carregarTudo)
</script>

<template>
  <div class="p-4 sm:p-6 max-w-4xl mx-auto w-full">
    <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between mb-4">
      <div>
        <h1 class="text-2xl font-bold">
          Ranking do sábado
        </h1>
        <p
          v-if="dataFormatada"
          class="text-sm text-surface-500 capitalize"
        >
          {{ dataFormatada }}
        </p>
      </div>
      <EncontroSeletor
        :encontros="encontros"
        :encontro="encontro"
        @selecionar="aoSelecionarEncontro"
      />
    </div>

    <div
      v-if="carregandoInicial || carregandoEncontro || carregando"
      class="flex justify-center py-10"
    >
      <i class="pi pi-spin pi-spinner text-2xl text-surface-400" />
    </div>

    <Card
      v-else-if="!encontro"
      class="text-center py-6"
    >
      <template #content>
        <p class="text-surface-500">
          Selecione um sábado para ver o ranking.
        </p>
      </template>
    </Card>

    <div
      v-else-if="linhas.length === 0"
      class="text-center py-10 text-surface-500"
    >
      <i class="pi pi-trophy text-3xl mb-2 block text-surface-300" />
      <p>Nenhuma folha lançada neste sábado ainda.</p>
    </div>

    <div
      v-else
      class="flex flex-col gap-4"
    >
      <div
        v-if="profile?.role !== 'diretor_clube'"
        class="flex flex-col gap-2"
      >
        <Card>
          <template #title>
            <h2 class="font-semibold flex items-center gap-2">
              <i class="pi pi-trophy text-primary" />
              Ranking geral
            </h2>
          </template>
          <template #content>
            <ul class="flex flex-col gap-1">
              <li
                v-for="l in geral"
                :key="`geral-${l.oansista_id}`"
                class="flex items-center justify-between gap-2 rounded-md px-2 py-1 even:bg-surface-50 dark:even:bg-surface-900"
              >
                <span class="flex items-center gap-2 min-w-0">
                  <span
                    class="w-8 shrink-0 font-semibold"
                    :class="classePosicao(l.posicao)"
                  >
                    {{ l.posicao }}º
                  </span>
                  <span class="text-sm truncate">{{ l.oansista_nome }}</span>
                  <span class="text-xs text-surface-500 shrink-0">
                    {{ l.clube_nome }}
                  </span>
                </span>
                <span class="flex items-center gap-1 shrink-0">
                  <span class="font-semibold text-sm">{{ l.total }}</span>
                  <span class="text-xs text-surface-500">pts</span>
                  <span v-if="medalha(l.posicao)">
                    {{ medalha(l.posicao) }}
                  </span>
                </span>
              </li>
            </ul>
          </template>
        </Card>
      </div>

      <div
        v-for="secao in secoes"
        :key="secao.nome"
        class="flex flex-col gap-2"
      >
        <Card>
          <template #title>
            <h2 class="font-semibold">
              {{ secao.nome }}
            </h2>
          </template>
          <template #content>
            <ul class="flex flex-col gap-1">
              <li
                v-for="l in secao.linhas"
                :key="`${secao.nome}-${l.oansista_id}`"
                class="flex items-center justify-between gap-2 rounded-md px-2 py-1 even:bg-surface-50 dark:even:bg-surface-900"
              >
                <span class="flex items-center gap-2 min-w-0">
                  <span
                    class="w-8 shrink-0 font-semibold"
                    :class="classePosicao(l.posicao)"
                  >
                    {{ l.posicao }}º
                  </span>
                  <span class="text-sm truncate">{{ l.oansista_nome }}</span>
                </span>
                <span class="flex items-center gap-1 shrink-0">
                  <span class="font-semibold text-sm">{{ l.total }}</span>
                  <span class="text-xs text-surface-500">pts</span>
                  <span v-if="medalha(l.posicao)">
                    {{ medalha(l.posicao) }}
                  </span>
                </span>
              </li>
            </ul>
          </template>
        </Card>
      </div>
    </div>
  </div>
</template>