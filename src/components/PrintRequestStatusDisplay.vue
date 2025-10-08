<template>
  <div class="print-request-status">
    <!-- No Print Requests -->
    <div v-if="!printRequests || printRequests.length === 0" class="flex items-center gap-2">
      <i class="pi pi-circle text-slate-300 text-xs"></i>
      <span class="text-xs text-slate-500">{{ $t('print.no_requests') }}</span>
    </div>

    <!-- Single Active Print Request -->
    <div v-else-if="activeRequest" class="space-y-1">
      <div class="flex items-center justify-between">
        <div class="flex items-center gap-2">
          <Tag 
            :value="activeRequest.status.replace('_', ' ')" 
            :severity="getPrintRequestStatusSeverity(activeRequest.status)"
            class="px-2 py-1 text-xs"
          />
          <i v-if="activeRequest.status === 'SHIPPED'" 
             class="pi pi-truck text-blue-600 text-xs" 
             v-tooltip.top="$t('print.in_transit')"></i>
        </div>
        
        <!-- Withdraw button for SUBMITTED status -->
        <Button 
          v-if="activeRequest.status === 'SUBMITTED'"
          icon="pi pi-times" 
          severity="danger" 
          size="small"
          text
          @click="$emit('withdraw-request', activeRequest, batch)"
          v-tooltip.top="$t('print.withdraw_request')"
        />
      </div>
      
      <!-- Request date -->
      <div class="text-xs text-slate-500">
        {{ formatDate(activeRequest.requested_at) }}
      </div>
      
      <!-- Shipping address (truncated) -->
      <div v-if="activeRequest.shipping_address" class="text-xs text-slate-600 max-w-32 truncate" 
           v-tooltip.top="activeRequest.shipping_address">
        <i class="pi pi-map-marker mr-1"></i>{{ truncateAddress(activeRequest.shipping_address) }}
      </div>
    </div>

    <!-- Multiple Print Requests (History) -->
    <div v-else-if="hasHistory" class="space-y-1">
      <div class="flex items-center gap-2">
        <Tag 
          :value="$t('print.history')" 
          severity="secondary" 
          class="px-2 py-1 text-xs"
        />
        <Button 
          icon="pi pi-history" 
          severity="secondary" 
          size="small"
          text
          @click="showHistory = !showHistory"
          v-tooltip.top="$t('print.view_history')"
        />
      </div>
      
      <!-- Expandable history -->
      <div v-if="showHistory" class="mt-2 space-y-1 max-h-32 overflow-y-auto">
        <div v-for="request in printRequests" :key="request.id" 
             class="text-xs p-2 bg-slate-50 rounded border"
             :class="{ 'border-red-200 bg-red-50': isWithdrawn(request) }">
          <div class="flex items-center justify-between mb-1">
            <Tag 
              :value="request.status.replace('_', ' ')" 
              :severity="getPrintRequestStatusSeverity(request.status)"
              class="px-1 py-0.5 text-xs"
            />
            <span class="text-xs text-slate-500">{{ formatDate(request.requested_at) }}</span>
          </div>
          <div v-if="isWithdrawn(request)" class="text-red-600 text-xs">
            <i class="pi pi-times-circle mr-1"></i>{{ $t('print.withdrawn_by_user') }}
          </div>
        </div>
      </div>
    </div>

    <!-- Available for Print Request -->
    <div v-else class="flex items-center gap-2">
      <Button 
        :label="$t('print.request_print')" 
        icon="pi pi-print" 
        severity="info" 
        size="small"
        @click="$emit('request-print', batch)"
        v-tooltip.top="$t('print.submit_request')"
      />
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'primevue/button';
import Tag from 'primevue/tag';

const { t } = useI18n();

const props = defineProps({
  batch: {
    type: Object,
    required: true
  },
  printRequests: {
    type: Array,
    default: () => []
  }
});

const emit = defineEmits(['request-print', 'withdraw-request']);

const showHistory = ref(false);

const activeRequest = computed(() => {
  return props.printRequests?.find(pr => 
    !['COMPLETED', 'CANCELLED'].includes(pr.status)
  );
});

const hasHistory = computed(() => {
  return props.printRequests?.length > 0 && !activeRequest.value;
});

const isWithdrawn = (request) => {
  return request.status === 'CANCELLED' && 
         request.admin_notes?.includes('Withdrawn by card issuer');
};

const getPrintRequestStatusSeverity = (status) => {
  switch (status) {
    case 'SUBMITTED': return 'info';
    case 'PAYMENT_PENDING': return 'contrast';
    case 'PROCESSING': return 'warning';
    case 'SHIPPED': return 'primary';
    case 'COMPLETED': return 'success';
    case 'CANCELLED': return 'danger';
    default: return 'secondary';
  }
};

const formatDate = (dateString) => {
  if (!dateString) return '-';
  return new Date(dateString).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  });
};

const truncateAddress = (address) => {
  if (!address) return '';
  const firstLine = address.split('\n')[0];
  return firstLine.length > 25 ? firstLine.substring(0, 25) + '...' : firstLine;
};
</script>

<style scoped>
.print-request-status {
  min-height: 2rem;
}
</style> 