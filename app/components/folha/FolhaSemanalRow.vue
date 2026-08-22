<script setup lang="ts">
import type { FormFolha } from '~/composables/useFolhaSemanal'
import { previewTotalFolha, type ItensPontuacaoMap } from '~/utils/pontos'

const props = defineProps<{
  nome: string
  folha: FormFolha | null
  presente: boolean
  pontos: ItensPontuacaoMap
  salvando: boolean
}>()

const emit = defineEmits<{ salvar: [form: FormFolha] }>()

const form = reactive<FormFolha>({
  uniforme: props.folha?.uniforme ?? false,
  biblia: props.folha?.biblia ?? false,
  ebd: props.folha?.ebd ?? false,
  manual: props.folha?.manual ?? false,
  conduta: props.folha?.conduta ?? false,
  secoes_dia: props.folha?.secoes_dia ?? 0,
  atividade_extra: props.folha?.atividade_extra ?? 0,
})

const sujo = computed(() => {
  const f = props.folha
  if (!f) return true
  return form.uniforme !== f.uniforme
    || form.biblia !== f.biblia
    || form.ebd !== f.ebd
    || form.manual !== f.manual
    || form.conduta !== f.conduta
    || form.secoes_dia !== f.secoes_dia
    || form.atividade_extra !== f.atividade_extra
})

const total = computed(() => previewTotalFolha(props.pontos, form, props.presente))

function salvar() {
  emit('salvar', { ...form })
}
</script>

<template>
  <div class="rounded-lg border border-default p-4">
    <div class="flex items-center justify-between gap-3 mb-3">
      <div class="flex items-center gap-3 min-w-0">
        <UAvatar
          :alt="nome"
          size="sm"
        />
        <span class="font-medium truncate">{{ nome }}</span>
      </div>
      <div class="flex items-center gap-2 shrink-0">
        <UBadge
          variant="soft"
          color="success"
        >
          {{ total }} pts
        </UBadge>
        <UButton
          icon="i-lucide-save"
          size="sm"
          :disabled="!sujo"
          :loading="salvando"
          @click="salvar"
        >
          Salvar
        </UButton>
      </div>
    </div>

    <div class="grid grid-cols-2 sm:grid-cols-3 gap-x-4 gap-y-2">
      <UCheckbox
        v-model="form.uniforme"
        label="Uniforme"
      />
      <UCheckbox
        v-model="form.biblia"
        label="Bíblia"
      />
      <UCheckbox
        v-model="form.ebd"
        label="EBD"
      />
      <UCheckbox
        v-model="form.manual"
        label="Manual"
      />
      <UCheckbox
        v-model="form.conduta"
        label="Conduta"
      />
      <div class="flex items-center justify-between gap-2">
        <span class="text-sm text-muted">Seções</span>
        <UInputNumber
          v-model="(form.secoes_dia as any)"
          :min="0"
          :max="99"
          class="w-24"
        />
      </div>
      <div class="flex items-center justify-between gap-2">
        <span class="text-sm text-muted">Extra</span>
        <UInputNumber
          v-model="(form.atividade_extra as any)"
          :min="0"
          :max="999"
          class="w-24"
        />
      </div>
    </div>
  </div>
</template>
