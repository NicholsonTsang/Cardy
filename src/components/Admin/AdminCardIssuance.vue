<template>
  <div>
    <!-- Loading State -->
    <div v-if="isLoading" class="space-y-4">
      <div v-for="i in 3" :key="i" class="animate-pulse bg-slate-200 h-24 rounded-lg"></div>
    </div>

    <!-- Empty State -->
    <div v-else-if="batches.length === 0" class="text-center py-12">
      <i class="pi pi-inbox text-5xl text-slate-300 mb-3"></i>
      <h3 class="text-lg font-medium text-slate-700 mb-2">No Batches Issued</h3>
      <p class="text-slate-500">This card has no issued batches yet.</p>
    </div>

    <!-- Batches Table -->
    <div v-else>
      <DataTable
        :value="batches"
        class="text-sm"
        stripedRows
        responsiveLayout="scroll"
      >
        <Column field="batch_name" header="Batch Name" :style="{ minWidth: '150px' }">
          <template #body="{ data }">
            <span class="font-medium text-slate-900">{{ data.batch_name }}</span>
          </template>
        </Column>
        
        <Column field="batch_number" header="Number" :style="{ minWidth: '100px' }">
          <template #body="{ data }">
            <span class="text-slate-700">#{{ data.batch_number }}</span>
          </template>
        </Column>
        
        <Column field="cards_count" header="Cards Count" :style="{ minWidth: '120px' }">
          <template #body="{ data }">
            <Tag :value="`${data.cards_count}`" severity="info" />
          </template>
        </Column>
        
        <Column field="payment_status" header="Payment" :style="{ minWidth: '120px' }">
          <template #body="{ data }">
            <Tag :value="data.payment_status" :severity="getPaymentSeverity(data.payment_status)" />
          </template>
        </Column>
        
        <Column field="is_disabled" header="Status" :style="{ minWidth: '100px' }">
          <template #body="{ data }">
            <Tag
              :value="data.is_disabled ? 'Disabled' : 'Active'"
              :severity="data.is_disabled ? 'danger' : 'success'"
            />
          </template>
        </Column>
        
        <Column field="created_at" header="Created" :style="{ minWidth: '120px' }">
          <template #body="{ data }">
            <span class="text-xs text-slate-600">{{ formatDate(data.created_at) }}</span>
          </template>
        </Column>
      </DataTable>
    </div>
  </div>
</template>

<script setup lang="ts">
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import Tag from 'primevue/tag'

interface Batch {
  id: string
  batch_name: string
  batch_number: number
  cards_count: number
  payment_status: string
  is_disabled: boolean
  created_at: string
}

interface Props {
  cardId: string
  batches: Batch[]
  isLoading: boolean
}

defineProps<Props>()

const getPaymentSeverity = (status: string) => {
  const normalized = status?.toUpperCase()
  switch (normalized) {
    case 'PAID':
    case 'COMPLETED':
      return 'success'
    case 'PENDING':
      return 'warning'
    case 'FREE':
      return 'success' // Admin-issued batches
    case 'WAIVED':
      return 'info'
    default:
      return 'secondary'
  }
}

const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric'
  })
}
</script>

<style scoped>
:deep(.p-datatable) {
  font-size: 0.875rem;
}

:deep(.p-datatable .p-datatable-tbody > tr > td) {
  padding: 0.75rem 1rem;
}

:deep(.p-datatable .p-datatable-thead > tr > th) {
  padding: 0.75rem 1rem;
  font-weight: 600;
  background-color: #f8fafc;
}
</style>

