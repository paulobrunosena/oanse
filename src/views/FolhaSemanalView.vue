<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import Avatar from 'primevue/avatar'
import Card from 'primevue/card'
import Tag from 'primevue/tag'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/composables/useAuth'
import { useEncontro } from '@/composables/useEncontro'
import { useFolhaSemanal, type FormFolha } from '@/composables/useFolhaSemanal'
import { useToast } from '@/composables/useToast'
import EncontroSeletor from '@/components/encontro/EncontroSeletor.vue'
import EncontroRetroativo from '@/components/encontro/EncontroRetroativo.vue'
import FolhaSemanalRow from '@/components/folha/FolhaSemanalRow.vue'
import type { Database } from '@/types/database.types'

type Oansista = Database['public']['Tables']['oansistas']['Row']
type Presenca = Database['public']['Tables']['presencas']['Row']

const toast = useToast()
const { user } = useAuth()
const { encontro, encontros, semAtividade, motivoSemAtividade, carregando: carregandoEncontro, carregar: carregarEncontro, selecionar } = useEncontro()
const { pontos, carregando: carregandoFolhas, carregar: carregarFolhas, folhaDe, salvar } = useFolhaSemanal()

const turma = ref<{ id: string, nome: string } | null>(null)
const oansistas = ref<Oansista[]>([])
const presencas = ref<Presenca[]>([])
const carregando = ref(true)
const salvandoId = ref<string | null>(null)

function presencaDe(o: Oansista): Presenca | undefined {
  return presencas.value.find(p => p.oansista_id === o.id)
}

function presente(o: Oansista): boolean {
  return presencaDe(o)?.presente ?? false
}

const presentes = computed(() => oansistas.value.filter(presente))

const dataFormatada = computed(() => {
  if (!encontro.value) return ''
  return new Date(`${encontro.value.data}T00:00:00`).toLocaleDateString('pt-BR', {
    weekday: 'long', day: 'numeric', month: 'long',
  })
})

async function carregarTurma() {
  if (!user.value?.sub) return
  const { data } = await supabase
    .from('turmas')
    .select('id, nome')
    .eq('lider_id', user.value.sub)
    .eq('ativo', true)
    .maybeSingle()
  turma.value = data ?? null

  if (!turma.value && encontro.value) {
    const { data: rem } = await supabase
      .from('remanejamentos_temporarios')
      .select('turma_id')
      .eq('encontro_id', encontro.value.id)
      .eq('lider_substituto_id', user.value.sub)
      .maybeSingle()
    if (rem) {
      const { data: t } = await supabase
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
  const { data } = await supabase
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
  const { data } = await supabase
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
  if (encontro.value) {
    await carregarFolhas(encontro.value.id, oansistas.value.map(o => o.id))
  }
  carregando.value = false
}

async function aoSelecionarEncontro(id: string) {
  selecionar(id)
  await carregarTurma()
  await carregarOansistas()
  await carregarPresencas()
  if (encontro.value) {
    await carregarFolhas(encontro.value.id, oansistas.value.map(o => o.id))
  }
}

async function onSalvar(o: Oansista, form: FormFolha) {
  if (!encontro.value || !user.value?.sub) return
  const presenca = presencaDe(o)
  if (!presenca) return
  salvandoId.value = o.id
  try {
    await salvar(encontro.value.id, o.id, presenca.id, user.value.sub, form)
  }
  catch (e) {
    toast.add({
      title: 'Erro ao salvar folha',
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
  <div class="p-4 sm:p-6 max-w-3xl mx-auto w-full">
    <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between mb-4">
      <div>
        <h1 class="text-2xl font-bold">
          Folha Semanal
        </h1>
        <p
          v-if="dataFormatada"
          class="text-sm text-surface-500 capitalize"
        >
          {{ dataFormatada }}
        </p>
      </div>
      <div class="flex flex-wrap items-center gap-3">
        <EncontroSeletor
          :encontros="encontros"
          :encontro="encontro"
          @selecionar="aoSelecionarEncontro"
        />
        <div
          v-if="turma && oansistas.length"
          class="text-sm text-surface-500"
        >
          {{ presentes.length }} / {{ oansistas.length }} presentes
        </div>
      </div>
    </div>

    <div class="flex justify-end mb-3">
      <EncontroRetroativo @criado="aoSelecionarEncontro" />
    </div>

    <div
      v-if="carregando || carregandoEncontro || carregandoFolhas"
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
            Não é possível lançar folha neste dia.
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

      <div
        v-else
        class="flex flex-col gap-3"
      >
        <template
          v-for="o in oansistas"
          :key="o.id"
        >
          <FolhaSemanalRow
            v-if="presente(o)"
            :nome="o.nome"
            :folha="folhaDe(o.id) ?? null"
            :presente="true"
            :pontos="pontos"
            :salvando="salvandoId === o.id"
            @salvar="form => onSalvar(o, form)"
          />
          <div
            v-else
            class="flex items-center justify-between gap-3 rounded-lg border border-dashed bg-[var(--surface-card)] p-3 opacity-70"
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
                severity="secondary"
                value="Ausente — 0 pts"
              />
            </div>
          </div>
        </template>
      </div>

      <p class="text-xs text-surface-500 mt-4">
        Ausentes ficam com o total zerado (regra automática). O total é calculado
        pela configuração de pontuação definida pelo Diretor Geral.
      </p>
    </template>
  </div>
</template>
