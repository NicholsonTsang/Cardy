<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import Dialog from 'primevue/dialog'
import InputText from 'primevue/inputtext'
import Button from 'primevue/button'
import ProgressBar from 'primevue/progressbar'
import { useCardStore } from '@/stores/card'
import { useToast } from 'primevue/usetoast'

interface Props {
  visible: boolean
  card: {
    id: string
    name: string
  } | null
}

const props = defineProps<Props>()

const emit = defineEmits<{
  'update:visible': [value: boolean]
  'duplicated': [newCardId: string]
}>()

const { t } = useI18n()
const cardStore = useCardStore()
const toast = useToast()

const newName = ref('')
const nameError = ref('')

// Sync default name when card changes
watch(() => props.card, (card) => {
  if (card) {
    newName.value = t('dashboard.duplicate_name_prefix', { name: card.name })
    nameError.value = ''
  }
}, { immediate: true })

const dialogVisible = computed({
  get: () => props.visible,
  set: (val) => emit('update:visible', val)
})

const isValid = computed(() => {
  return newName.value.trim().length > 0
})

const handleDuplicate = async () => {
  if (!props.card || !isValid.value) return

  nameError.value = ''

  const result = await cardStore.duplicateCard(props.card.id, newName.value.trim())

  if (result) {
    toast.add({
      severity: 'success',
      summary: t('dashboard.duplicate_success'),
      detail: t('dashboard.duplicate_success_detail', { name: newName.value.trim() }),
      life: 4000
    })
    emit('duplicated', result)
    dialogVisible.value = false
  } else {
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: cardStore.error || t('dashboard.duplicate_failed'),
      life: 5000
    })
  }
}

const handleCancel = () => {
  dialogVisible.value = false
  nameError.value = ''
}
</script>

<template>
  <Dialog
    v-model:visible="dialogVisible"
    modal
    :header="t('dashboard.duplicate_card')"
    :style="{ width: '90vw', maxWidth: '32rem' }"
    class="standardized-dialog"
    :closable="!cardStore.isDuplicating"
    :closeOnEscape="!cardStore.isDuplicating"
    :dismissableMask="!cardStore.isDuplicating"
  >
    <div class="space-y-4 py-2">
      <!-- Card being duplicated -->
      <div v-if="card" class="flex items-center gap-3 p-3 bg-slate-50 rounded-lg">
        <div class="w-10 h-10 rounded-lg bg-blue-100 flex items-center justify-center flex-shrink-0">
          <i class="pi pi-copy text-blue-600"></i>
        </div>
        <div class="min-w-0">
          <p class="text-sm font-medium text-slate-900 truncate">{{ card.name }}</p>
          <p class="text-xs text-slate-500">{{ t('dashboard.duplicate_card_desc') }}</p>
        </div>
      </div>

      <!-- New name input -->
      <div>
        <label class="block text-sm font-medium text-slate-700 mb-1.5">
          {{ t('dashboard.new_card_name') }}
        </label>
        <InputText
          v-model="newName"
          class="w-full"
          :placeholder="t('dashboard.enter_card_name')"
          :disabled="cardStore.isDuplicating"
          @keyup.enter="handleDuplicate"
          autofocus
        />
        <small v-if="nameError" class="text-red-500 text-xs mt-1">{{ nameError }}</small>
      </div>

      <!-- Progress indicator -->
      <div v-if="cardStore.isDuplicating" class="space-y-2">
        <div class="flex items-center gap-2 text-sm text-slate-600">
          <i class="pi pi-spin pi-spinner text-blue-600"></i>
          <span>{{ t('dashboard.duplicating_card') }}</span>
        </div>
        <ProgressBar
          :value="cardStore.duplicateProgress"
          :showValue="false"
          class="h-2"
        />
      </div>
    </div>

    <template #footer>
      <div class="flex justify-end gap-2">
        <Button
          :label="t('common.cancel')"
          severity="secondary"
          text
          :disabled="cardStore.isDuplicating"
          @click="handleCancel"
        />
        <Button
          :label="t('dashboard.duplicate_card')"
          icon="pi pi-copy"
          :loading="cardStore.isDuplicating"
          :disabled="!isValid"
          @click="handleDuplicate"
        />
      </div>
    </template>
  </Dialog>
</template>
