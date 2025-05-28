<template>
    <div class="space-y-6">
        <!-- Page Header -->
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
            <div>
                <h1 class="text-2xl font-bold text-slate-900">Profile Settings</h1>
                <p class="text-slate-600 mt-1">Manage your account information and preferences</p>
            </div>
        </div>

        <!-- Profile Content -->
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <!-- Profile Information -->
            <div class="lg:col-span-2 bg-white rounded-xl shadow-lg border border-slate-200 p-6">
                <h2 class="text-lg font-semibold text-slate-900 mb-4">Personal Information</h2>
                
                <div class="space-y-4">
                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                        <div>
                            <label class="block text-sm font-medium text-slate-700 mb-2">First Name</label>
                            <InputText placeholder="Enter your first name" class="w-full" />
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-slate-700 mb-2">Last Name</label>
                            <InputText placeholder="Enter your last name" class="w-full" />
                        </div>
                    </div>
                    
                    <div>
                        <label class="block text-sm font-medium text-slate-700 mb-2">Email Address</label>
                        <InputText placeholder="Enter your email" type="email" class="w-full" />
                    </div>
                    
                    <div>
                        <label class="block text-sm font-medium text-slate-700 mb-2">Phone Number</label>
                        <InputText placeholder="Enter your phone number" class="w-full" />
                    </div>
                    
                    <div class="flex justify-end pt-4">
                        <Button label="Save Changes" class="shadow-lg hover:shadow-xl transition-shadow" />
                    </div>
                </div>
            </div>

            <!-- Profile Picture & Quick Actions -->
            <div class="space-y-6">
                <!-- Profile Picture -->
                <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6 text-center">
                    <div class="w-24 h-24 bg-gradient-to-r from-blue-500 to-indigo-500 rounded-full flex items-center justify-center mx-auto mb-4">
                        <i class="pi pi-user text-white text-3xl"></i>
                    </div>
                    <h3 class="font-medium text-slate-900 mb-2">Profile Picture</h3>
                    <p class="text-sm text-slate-500 mb-4">Upload a new profile picture</p>
                    <Button label="Upload Photo" outlined />
                </div>

                <!-- Account Status -->
                <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
                    <h3 class="font-medium text-slate-900 mb-4">Account Status</h3>
                    <div class="space-y-3">
                        <div class="flex items-center justify-between">
                            <span class="text-sm text-slate-600">Account Type</span>
                            <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
                                Premium
                            </span>
                        </div>
                        <div class="flex items-center justify-between">
                            <span class="text-sm text-slate-600">Member Since</span>
                            <span class="text-sm text-slate-900">Jan 2024</span>
                        </div>
                        <div class="flex items-center justify-between">
                            <span class="text-sm text-slate-600">Cards Created</span>
                            <span class="text-sm text-slate-900">12</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import Button from 'primevue/button';
import InputText from 'primevue/inputtext';
</script>