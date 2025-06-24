<template>
    <div class="bg-white rounded-xl shadow-lg border border-slate-200 overflow-hidden">
        <div class="p-8 text-center">
            <div class="w-20 h-20 bg-gradient-to-r from-blue-500 to-indigo-500 rounded-full mx-auto mb-6 flex items-center justify-center">
                <i class="pi pi-user text-2xl text-white"></i>
            </div>
            
            <h2 class="text-2xl font-bold text-slate-900 mb-4">Welcome to Cardy</h2>
            <p class="text-slate-600 text-lg mb-8 max-w-md mx-auto">
                Create your profile to get started with creating and sharing digital cards.
            </p>
            
            <Button 
                label="Create Profile" 
                icon="pi pi-user-plus"
                @click="emit('start-profile')"
                size="large"
                class="px-8 py-3 bg-gradient-to-r from-blue-500 to-indigo-500 hover:from-blue-600 hover:to-indigo-600 border-0 shadow-lg hover:shadow-xl transform hover:-translate-y-0.5 transition-all"
            />
            
            <div class="mt-8 text-sm text-slate-500">
                <p>You can verify your identity later for additional features</p>
            </div>
        </div>
    </div>
</template>

<script setup>
import Button from 'primevue/button'

const emit = defineEmits(['start-profile'])
</script> 