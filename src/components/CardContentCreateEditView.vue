<template>
    <div>
        <div class="2xl:flex">
            <!-- Artwork Section -->
            <div class="mb-6 2xl:mb-0 2xl:mr-8">
                <div class="font-semibold mb-2">Image</div>
                <div class="w-60">
                    <div class="h-90 border border-gray-300 rounded-md p-2 relative mb-4"
                        :class="{ 'border-dashed': !previewImage }">
                        <img :src="previewImage || cardPlaceholder" alt="Card Artwork Preview"
                            class="object-cover h-full w-full rounded" />
                        <div v-if="!previewImage"
                            class="absolute inset-0 flex items-center justify-center text-gray-500 text-center p-2">
                            Click below to upload
                        </div>
                    </div>
                    <FileUpload mode="basic" name="artworkUpload" accept="image/*" :maxFileSize="1000000"
                        chooseLabel="Upload Artwork" chooseIcon="pi pi-upload" @select="handleImageUpload" :auto="false"
                        customUpload class="w-full p-button-primary" />
                </div>
            </div>

            <!-- Form Fields Section -->
            <div class="w-full">

                <div class="mb-4">
                    <label class="font-semibold block mb-1">Name</label>
                    <InputText id="cardName" type="text" v-model="formData.name" class="w-full" />
                </div>

                <div class="mb-4">
                    <label class="font-semibold block mb-1">Description</label>
                    <Textarea id="cardDescription" v-model="formData.description" rows="5" class="w-full" />
                </div>

                <div class="mb-4">
                    <label class="font-semibold block mb-1">Conversation AI Enabled</label>
                    <ToggleSwitch size="small" v-model="formData.conversationAiEnabled" />
                </div>

                <div class="mb-4" v-if="formData.conversationAiEnabled">
                    <label class="font-semibold block mb-1">AI Prompt</label>
                    <Textarea id="cardDescription" v-model="formData.aiPrompt" rows="5" class="w-full" />
                </div>
            </div>
        </div>

    </div>
</template>

<script setup>
import { ref } from 'vue';
import FileUpload from 'primevue/fileupload';
import Button from 'primevue/button';
import Textarea from 'primevue/textarea';
import InputText from 'primevue/inputtext';
import ToggleSwitch from 'primevue/toggleswitch';
import cardPlaceholder from '@/assets/images/card-placeholder.svg';

const formData = ref({
    name: '',
    description: '',
    images: [],
    conversationAiEnabled: false,
    aiPrompt: ''
});

const previewImage = ref(null);

const handleImageUpload = (event) => {
    console.log(event);
};

const handleCancelEdit = () => {
    console.log('Cancel Edit');
};

const handleUpdate = () => {
    console.log('Update');
};


</script>