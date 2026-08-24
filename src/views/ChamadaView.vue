<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import Avatar from 'primevue/avatar'
import Card from 'primevue/card'
import ToggleSwitch from 'primevue/toggleswitch'
import Tag from 'primevue/tag'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/composables/useAuth'
import { useEncontro } from '@/composables/useEncontro'
import { useToast } from '@/composables/useToast'
import EncontroSeletor from '@/components/encontro/EncontroSeletor.vue'
import type { Database } from '@/types/database.types'

type Oansista = Database['public']['Tables']['oansistas']['Row']
type Presenca = Database['public']['Tables']['presencas']['Row']

const supabaseClient = supabase
const toast = useToast()
const { user } = useAuth()
const { encontro, encontros, semAtividade, motivoSemAtividade, carregando: carregandoEncontro, carregar: carregarEncontro, selecionar } = useEncontro()

const turma = ref<{ id: string, nome: string } | null>(null)
const oansistas = ref<Oansista[]>([])
const presencas = ref<Presenca[]>([])
const carregando = ref(true)
const salvandoId = ref<string | null>(null)

const presencaPorOansista = computed(() => {
  const mapa = new Map<string, Presenca>()
  for (const p of presencas.value) mapa.set(p.oansista_id, p)
  return mapa
})

const presentes = computed(() => presencas.value.filter(p => p.presente).length)

function presente(o: Oansista): boolean {
  return presencaPorOansista.value.get(o.id)?.presente ?? false
}

const dataFormatada = computed(() => {
  if (!encontro.value) return ''
  return new Date(`${encontro.value.data}T00:00:00`).toLocaleDateString('pt-BR', {
    weekday: 'long', day: 'numeric', month: 'long',
  })
})

async function carregarTurma() {
  if (!user.value?.sub) return
  const { data } = await supabaseClient
    .from('turmas')
    .select('id, nome')
    .eq('lider_id', user.value.sub)
    .eq('ativo', true)
    .maybeSingle()
  turma.value = data ?? null

  if (!turma.value && encontro.value) {
    const { data: rem } = await supabaseClient
      .from('remanejamentos_temporarios')
      .select('turma_id')
      .eq('encontro_id', encontro.value.id)
      .eq('lider_substituto_id', user.value.sub)
      .maybeSingle()
    if (rem) {
      const { data: t } = await supabaseClient
        .from('turmas')
        .select('id, nome')
        .eq('id', rem.turma_id)
        .maybeSingle()
      turma.value = t ?? null
    }
  }
}

async function carregarOansistas() {
  if (!turma.value) {
    oansistas.value = []
    return
  }
  const { data } = await supabaseClient
    .from('oansistas')
    .select('*')
    .eq('turma_id', turma.value.id)
    .eq('status', 'ativo')
    .order('nome')
  oansistas.value = data ?? []
}

async function carregarPresencas() {
  if (!encontro.value || oansistas.value.length === 0) {
    presencas.value = []
    return
  }
  const ids = oansistas.value.map(o => o.id)
  const { data } = await supabaseClient
    .from('presencas')
    .select('*')
    .eq('encontro_id', encontro.value.id)
    .in('oansista_id', ids)
  presencas.value = data ?? []
}

async function carregarTudo() {
  carregando.value = true
  await carregarEncontro()
  await carregarTurma()
  await carregarOansistas()
  await carregarPresencas()
  carregando.value = false
}

async function aoSelecionarEncontro(id: string) {
  selecionar(id)
  await carregarTurma()
  await carregarOansistas()
  await carregarPresencas()
}

async function alternar(o: Oansista) {
  if (!encontro.value || !user.value?.sub) return
  salvandoId.value = o.id
  const existente = presencaPorOansista.value.get(o.id)

  try {
    if (existente) {
      const { error } = await supabaseClient
        .from('presencas')
        .update({ presente: !existente.presente })
        .eq('id', existente.id)
      if (error) throw error
      existente.presente = !existente.presente
    }
    else {
      const { data: nova, error } = await supabaseClient
        .from('presencas')
        .insert({
          encontro_id: encontro.value.id,
          oansista_id: o.id,
          presente: true,
          lider_registrante_id: user.value.sub,
        })
        .select()
        .single()
      if (error || !nova) throw error

      const { error: errFolha } = await supabaseClient
        .from('folhas_semanais')
        .insert({
          encontro_id: encontro.value.id,
          oansista_id: o.id,
          presenca_id: nova.id,
          registrado_por: user.value.sub,
        })
      if (errFolha) throw errFolha

      presencas.value.push(nova)
    }
  }
  catch (e) {
    toast.add({
      title: 'Erro ao lançar presença',
      description: (e as { message?: string })?.message ?? 'Tente novamente',
      color: 'error',
    })
  }
  finally {
    salvandoId.value = null
  }
}

onMounted(carregarTudo)
</script>

<template>
  <div class="p-4 sm:p-6 max-w-2xl mx-auto w-full">
    <div class="flex items-center justify-between gap-3 mb-4">
      <div>
        <h1 class="text-2xl font-bold">
          Chamada
        </h1>
        <p
          v-if="dataFormatada"
          class="text-sm text-surface-500 capitalize"
        >
          {{ dataFormatada }}
        </p>
      </div>
      <div class="flex items-center gap-3">
        <EncontroSeletor
          :encontros="encontros"
          :encontro="encontro"
          @selecionar="aoSelecionarEncontro"
        />
        <div
          v-if="turma && oansistas.length"
          class="text-sm text-surface-500"
        >
          {{ presentes }} / {{ oansistas.length }} presentes
        </div>
      </div>
    </div>

    <div
      v-if="carregando || carregandoEncontro"
      class="flex justify-center py-10"
    >
      <i class="pi pi-spin pi-spinner text-2xl text-surface-400" />
    </div>

    <Card
      v-else-if="semAtividade"
      class="text-center py-6"
    >
      <template #content>
        <div class="flex flex-col items-center gap-2">
          <i class="pi pi-calendar-minus text-2xl text-surface-400" />
          <p class="font-medium">
            Neste sábado não há Oanse
          </p>
          <p
            v-if="motivoSemAtividade"
            class="text-sm text-surface-500"
          >
            Motivo: {{ motivoSemAtividade }}
          </p>
          <p class="text-sm text-surface-500">
            Não é possível lançar chamada neste dia.
          </p>
        </div>
      </template>
    </Card>

    <Card
      v-else-if="!turma"
      class="text-center py-6"
    >
      <template #content>
        <p class="text-surface-500">
          Você ainda não tem uma turma atribuída. Procure o Diretor do seu clube.
        </p>
      </template>
    </Card>

    <template v-else-if="turma">
      <p class="text-sm text-surface-500 mb-3">
        Turma: <strong>{{ turma.nome }}</strong>
      </p>

      <div
        v-if="oansistas.length === 0"
        class="text-center py-8 text-surface-500"
      >
        Nenhuma criança ativa nesta turma.
      </div>

      <ul
        v-else
        class="flex flex-col gap-2"
      >
        <li
          v-for="o in oansistas"
          :key="o.id"
          class="flex items-center justify-between gap-3 rounded-lg border p-3"
        >
          <div class="flex items-center gap-3 min-w-0">
            <Avatar
              :label="o.nome.charAt(0).toUpperCase()"
              size="small"
            />
            <span class="font-medium truncate">{{ o.nome }}</span>
          </div>
          <div class="flex items-center gap-2 shrink-0">
            <Tag
              :severity="presente(o) ? 'success' : 'secondary'"
              :value="presente(o) ? 'Presente' : 'Falta'"
            />
            <ToggleSwitch
              :model-value="presente(o)"
              :loading="salvandoId === o.id"
              @update:model-value="alternar(o)"
            />
          </div>
        </li>
      </ul>
    </template>
  </div>
</template>
