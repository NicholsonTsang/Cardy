<template>
    <div class="space-y-6">
        <!-- Page Header -->
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
            <div>
                <h1 class="text-2xl font-bold text-slate-900">Issued Cards</h1>
                <p class="text-slate-600 mt-1">View and manage cards that have been issued to recipients</p>
            </div>
            <Button 
                icon="pi pi-plus" 
                label="Issue New Card" 
                severity="primary" 
                class="shadow-lg hover:shadow-xl transition-shadow"
            />
        </div>

        <!-- Stats Cards -->
        <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
                <div class="flex items-center">
                    <div class="p-3 rounded-full bg-blue-100">
                        <i class="pi pi-send text-blue-600 text-xl"></i>
                    </div>
                    <div class="ml-4">
                        <p class="text-sm font-medium text-slate-600">Total Issued</p>
                        <p class="text-2xl font-bold text-slate-900">247</p>
                    </div>
                </div>
            </div>
            
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
                <div class="flex items-center">
                    <div class="p-3 rounded-full bg-green-100">
                        <i class="pi pi-check-circle text-green-600 text-xl"></i>
                    </div>
                    <div class="ml-4">
                        <p class="text-sm font-medium text-slate-600">Active</p>
                        <p class="text-2xl font-bold text-slate-900">198</p>
                    </div>
                </div>
            </div>
            
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
                <div class="flex items-center">
                    <div class="p-3 rounded-full bg-yellow-100">
                        <i class="pi pi-clock text-yellow-600 text-xl"></i>
                    </div>
                    <div class="ml-4">
                        <p class="text-sm font-medium text-slate-600">Pending</p>
                        <p class="text-2xl font-bold text-slate-900">32</p>
                    </div>
                </div>
            </div>
            
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
                <div class="flex items-center">
                    <div class="p-3 rounded-full bg-red-100">
                        <i class="pi pi-times-circle text-red-600 text-xl"></i>
                    </div>
                    <div class="ml-4">
                        <p class="text-sm font-medium text-slate-600">Expired</p>
                        <p class="text-2xl font-bold text-slate-900">17</p>
                    </div>
                </div>
            </div>
        </div>

        <!-- Issued Cards Table -->
        <div class="bg-white rounded-xl shadow-lg border border-slate-200 overflow-hidden">
            <div class="p-6 border-b border-slate-200 bg-gradient-to-r from-slate-50 to-slate-100">
                <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
                    <h2 class="text-lg font-semibold text-slate-900">Recent Issued Cards</h2>
                    <div class="flex items-center gap-3">
                        <IconField>
                            <InputIcon class="pi pi-search" />
                            <InputText placeholder="Search cards..." class="w-64" />
                        </IconField>
                        <Button icon="pi pi-filter" outlined />
                    </div>
                </div>
            </div>
            
            <div class="p-6">
                <!-- Empty State -->
                <div class="flex flex-col items-center justify-center py-12 text-center">
                    <div class="w-16 h-16 bg-slate-100 rounded-full flex items-center justify-center mb-4">
                        <i class="pi pi-send text-2xl text-slate-400"></i>
                    </div>
                    <h3 class="text-lg font-medium text-slate-900 mb-2">No Issued Cards</h3>
                    <p class="text-slate-500 mb-4">Start issuing cards to see them here</p>
                    <Button 
                        icon="pi pi-plus" 
                        label="Issue First Card"
                    />
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import Button from 'primevue/button';
import IconField from 'primevue/iconfield';
import InputIcon from 'primevue/inputicon';
import InputText from 'primevue/inputtext';
</script>