<template>
    <div>
        <h2>Content Item Details</h2>

        <div class="flex">
            <div>
                <Galleria :value="formData.images" :responsiveOptions="responsiveOptions" :numVisible="5" :circular="true"
                    containerStyle="max-width: 640px">
                    <template #item="slotProps">
                        <img :src="slotProps.item.itemImageSrc" :alt="slotProps.item.alt"
                            style="width: 100%; display: block" />
                    </template>
                    <template #thumbnail="slotProps">
                        <img :src="slotProps.item.thumbnailImageSrc" :alt="slotProps.item.alt"
                            style="width: 100%; display: block" />
                    </template>
                </Galleria>
            </div>
            <div>
                <div class="mb-4">
                    <label for="cardName" class="font-semibold block mb-1">Card Name</label>
                    <InputText id="cardName" type="text" v-model="formData.name" class="w-full" />
                </div>

                <div class="mb-4">
                    <label for="cardDescription" class="font-semibold block mb-1">Card Description</label>
                    <Textarea id="cardDescription" v-model="formData.description" rows="5" class="w-full" />
                </div>
            </div>
        </div>

    </div>
</template>

<script setup>
import { ref } from 'vue';

const formData = ref({
    name: '',
    description: '',
    images: []
});

const responsiveOptions = ref([
    {
        breakpoint: '1300px',
        numVisible: 4
    },
    {
        breakpoint: '575px',
        numVisible: 1
    }
]);
</script>