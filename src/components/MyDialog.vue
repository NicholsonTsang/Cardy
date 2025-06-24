<template>
  <PDialog
    :visible="dialogVisible"
    @update:visible="val => dialogVisible = val"
    :header="props.header"
    :modal="props.modal"
    :style="props.style"
    :draggable="false"
    class="custom-dialog w-full mx-4 md:w-4/5 lg:w-3/4 xl:w-2/3 2xl:w-1/2"
    @hide="onInternalDialogHide"
    :maximizable="true"
    :closable="true"
  >
    <!-- Content slot for custom dialog content -->
    <div class="dialog-content max-h-[70vh] overflow-y-auto">
      <slot></slot>
    </div>
    
    <!-- Footer with action buttons -->
    <template #footer>
      <div class="flex justify-end gap-2 w-full">
        <Button 
          v-if="props.showCancel"
          :label="props.cancelLabel" 
          icon="pi pi-times" 
          :severity="props.cancelSeverity"
          text
          @click="handleCancel" 
        />
        <Button 
          v-if="props.showConfirm"
          :label="props.confirmLabel" 
          icon="pi pi-check" 
          :severity="props.confirmSeverity"
          :loading="loading" 
          @click="handleConfirm" 
        />
      </div>
    </template>
  </PDialog>

  <!-- Toast component for feedback messages -->
  <!-- <Toast position="bottom-right" /> -->
</template>

<script setup>
import { ref, watch } from 'vue';
import PDialog from 'primevue/dialog';
import Button from 'primevue/button';
import Toast from 'primevue/toast';
import { useToast } from 'primevue/usetoast';

const props = defineProps({
  modelValue: {
    type: Boolean,
    default: false
  },
  header: {
    type: String,
    default: 'Confirmation'
  },
  modal: {
    type: Boolean,
    default: true
  },
  style: [Object, String],
  confirmHandle: {
    type: Function,
    default: () => Promise.resolve()
  },
  confirmLabel: {
    type: String,
    default: 'Confirm'
  },
  confirmSeverity: {
    type: String,
    default: 'primary'
  },
  cancelLabel: {
    type: String,
    default: 'Cancel'
  },
  cancelSeverity: {
    type: String,
    default: 'secondary'
  },
  successMessage: {
    type: String,
    default: 'Operation completed successfully'
  },
  errorMessage: {
    type: String,
    default: 'An error occurred'
  },
  showConfirm: {
    type: Boolean,
    default: true
  },
  showCancel: {
    type: Boolean,
    default: true
  },
  showToasts: {
    type: Boolean,
    default: false
  },
});

const emit = defineEmits(['update:modelValue', 'cancel', 'hide']);

const toast = useToast();
const dialogVisible = ref(props.modelValue);
const loading = ref(false);

// Watch for model value changes from parent
watch(() => props.modelValue, (newValue) => {
  dialogVisible.value = newValue;
});

// Watch for local dialog visibility changes to emit back
watch(dialogVisible, (newValue) => {
  if (newValue !== props.modelValue) {
    emit('update:modelValue', newValue);
    if (!newValue) { // If dialog is being hidden
      emit('hide'); // Emit hide when dialogVisible becomes false
    }
  }
});

// Function to re-emit the hide event from PDialog
const onInternalDialogHide = () => {
  if (dialogVisible.value) { 
    dialogVisible.value = false; 
  } else { 
    emit('hide');
  }
};

// Handle confirm button click
const handleConfirm = async () => {
  try {
    loading.value = true;
    await props.confirmHandle();
    if (props.showToasts) {
    toast.add({
      severity: 'success',
      summary: 'Success',
      detail: props.successMessage,
      life: 3000
    });
    }
    dialogVisible.value = false;
  } catch (error) {
    if (props.showToasts) {
    const detailMessage = typeof error === 'string' ? error : (error?.message || props.errorMessage);
    toast.add({
      severity: 'error',
      summary: 'Error',
      detail: detailMessage,
      life: 5000
    });
    }
    // Re-throw the error so parent components can handle it
    throw error;
  } finally {
    loading.value = false;
  }
};

// Handle cancel button click
const handleCancel = () => {
  emit('cancel');
  dialogVisible.value = false;
};
</script>

<style scoped>
.dialog-content {
  @apply py-4;
}
</style>
