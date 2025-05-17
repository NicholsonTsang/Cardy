<template>
    <div class="p-4">
        <div class="flex justify-between items-center mb-6">
            <h1 class="text-2xl font-bold">Issued Cards</h1>
            <Button icon="pi pi-plus" label="Add New Card" severity="primary" />
        </div>

        <DataView :value="cards" :layout="layout" :paginator="true" :rows="9">
            <template #header>
                <div class="flex justify-content-end mb-3">
                    <Button icon="pi pi-th-large" @click="layout = 'grid'" :outlined="layout === 'list'" :class="{'p-button-active': layout === 'grid'}" class="mr-2" />
                    <Button icon="pi pi-bars" @click="layout = 'list'" :outlined="layout === 'grid'" :class="{'p-button-active': layout === 'list'}" />
                </div>
            </template>

            <template #grid="slotProps">
                <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                    <div v-for="card in slotProps.items" :key="card.id" class="col-span-1">
                        <Card class="shadow-md h-full">
                            <template #header>
                                <div class="relative overflow-hidden h-40 bg-gradient-to-r"
                                     :class="getCardColorClass(card.type)">
                                    <div class="absolute top-4 left-4 text-white">
                                        <div class="text-sm opacity-80">{{ card.bank }}</div>
                                        <div class="text-xl font-semibold mt-2">{{ formatCardNumber(card.number) }}</div>
                                    </div>
                                    <div class="absolute bottom-4 left-4 right-4 text-white flex justify-between items-end">
                                        <div>
                                            <div class="text-xs opacity-80">VALID THRU</div>
                                            <div>{{ card.expiryDate }}</div>
                                        </div>
                                        <div class="text-2xl">
                                            <i :class="getCardIcon(card.type)"></i>
                                        </div>
                                    </div>
                                </div>
                            </template>
                            <template #title>
                                <div class="flex justify-between items-center">
                                    <span>{{ card.name }}</span>
                                    <Tag :value="card.status" :severity="getStatusSeverity(card.status)" />
                                </div>
                            </template>
                            <template #content>
                                <div class="flex flex-col gap-3">
                                    <div class="flex justify-between">
                                        <span class="text-sm text-surface-600">Card Type</span>
                                        <span class="font-medium">{{ card.type }}</span>
                                    </div>
                                    <div class="flex justify-between">
                                        <span class="text-sm text-surface-600">Issued Date</span>
                                        <span class="font-medium">{{ card.issuedDate }}</span>
                                    </div>
                                    <div class="flex justify-between">
                                        <span class="text-sm text-surface-600">Limit</span>
                                        <span class="font-medium">${{ card.limit.toLocaleString() }}</span>
                                    </div>
                                </div>
                            </template>
                            <template #footer>
                                <div class="flex gap-2 justify-end mt-2">
                                    <Button icon="pi pi-lock" v-if="card.status === 'Active'" severity="secondary" outlined tooltip="Lock Card" />
                                    <Button icon="pi pi-lock-open" v-else severity="secondary" outlined tooltip="Unlock Card" />
                                    <Button icon="pi pi-pencil" severity="secondary" outlined tooltip="Edit Card" />
                                    <Button icon="pi pi-trash" severity="danger" outlined tooltip="Delete Card" />
                                </div>
                            </template>
                        </Card>
                    </div>
                </div>
            </template>

            <template #list="slotProps">
                <div class="flex flex-col gap-4">
                    <div v-for="card in slotProps.items" :key="card.id" class="border border-surface-200 rounded-lg overflow-hidden shadow-sm">
                        <div class="flex flex-col sm:flex-row">
                            <div class="w-full sm:w-64 bg-gradient-to-r" :class="getCardColorClass(card.type)">
                                <div class="p-4 h-full flex flex-col justify-between text-white">
                                    <div>
                                        <div class="text-sm opacity-80">{{ card.bank }}</div>
                                        <div class="text-lg font-semibold mt-1">{{ formatCardNumber(card.number) }}</div>
                                    </div>
                                    <div class="flex justify-between items-end">
                                        <div>
                                            <div class="text-xs opacity-80">VALID THRU</div>
                                            <div>{{ card.expiryDate }}</div>
                                        </div>
                                        <div class="text-xl">
                                            <i :class="getCardIcon(card.type)"></i>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div class="flex-1 p-4">
                                <div class="flex justify-between items-center mb-3">
                                    <div class="text-xl font-semibold">{{ card.name }}</div>
                                    <Tag :value="card.status" :severity="getStatusSeverity(card.status)" />
                                </div>
                                <div class="grid grid-cols-2 gap-3">
                                    <div>
                                        <div class="text-sm text-surface-600">Card Type</div>
                                        <div class="font-medium">{{ card.type }}</div>
                                    </div>
                                    <div>
                                        <div class="text-sm text-surface-600">Issued Date</div>
                                        <div class="font-medium">{{ card.issuedDate }}</div>
                                    </div>
                                    <div>
                                        <div class="text-sm text-surface-600">Expiry Date</div>
                                        <div class="font-medium">{{ card.expiryDate }}</div>
                                    </div>
                                    <div>
                                        <div class="text-sm text-surface-600">Limit</div>
                                        <div class="font-medium">${{ card.limit.toLocaleString() }}</div>
                                    </div>
                                </div>
                                <div class="flex gap-2 justify-end mt-4">
                                    <Button icon="pi pi-lock" v-if="card.status === 'Active'" severity="secondary" outlined tooltip="Lock Card" />
                                    <Button icon="pi pi-lock-open" v-else severity="secondary" outlined tooltip="Unlock Card" />
                                    <Button icon="pi pi-pencil" severity="secondary" outlined tooltip="Edit Card" />
                                    <Button icon="pi pi-trash" severity="danger" outlined tooltip="Delete Card" />
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </template>
        </DataView>
    </div>
</template>

<script>
export default {
    data() {
        return {
            layout: 'grid',
            cards: [
                {
                    id: 1,
                    name: 'Business Platinum',
                    number: '4532015112830366',
                    type: 'Visa',
                    bank: 'Global Bank',
                    status: 'Active',
                    issuedDate: '01/05/2023',
                    expiryDate: '01/27',
                    limit: 25000
                },
                {
                    id: 2,
                    name: 'Rewards Gold',
                    number: '5412751234567890',
                    type: 'Mastercard',
                    bank: 'City Finance',
                    status: 'Active',
                    issuedDate: '10/12/2022',
                    expiryDate: '10/26',
                    limit: 15000
                },
                {
                    id: 3,
                    name: 'Travel Elite',
                    number: '3715423456789012',
                    type: 'American Express',
                    bank: 'Premium Banking',
                    status: 'Inactive',
                    issuedDate: '05/20/2022',
                    expiryDate: '05/25',
                    limit: 30000
                },
                {
                    id: 4,
                    name: 'Everyday Spending',
                    number: '6011513456789018',
                    type: 'Discover',
                    bank: 'Universal Credit',
                    status: 'Active',
                    issuedDate: '03/15/2023',
                    expiryDate: '03/27',
                    limit: 8000
                },
                {
                    id: 5,
                    name: 'Business Essentials',
                    number: '4916338506153425',
                    type: 'Visa',
                    bank: 'Enterprise Bank',
                    status: 'Suspended',
                    issuedDate: '11/01/2022',
                    expiryDate: '11/26',
                    limit: 20000
                },
                {
                    id: 6,
                    name: 'Cashback Premier',
                    number: '5529081234567890',
                    type: 'Mastercard',
                    bank: 'Rewards Banking',
                    status: 'Active',
                    issuedDate: '07/08/2022',
                    expiryDate: '07/26',
                    limit: 12000
                }
            ]
        };
    },
    methods: {
        formatCardNumber(number) {
            return number.replace(/(\d{4})/g, '$1 ').trim();
        },
        getCardColorClass(type) {
            const types = {
                'Visa': 'from-blue-800 to-blue-600',
                'Mastercard': 'from-red-600 to-orange-600',
                'American Express': 'from-green-700 to-green-500',
                'Discover': 'from-orange-600 to-orange-400'
            };
            return types[type] || 'from-gray-800 to-gray-600';
        },
        getCardIcon(type) {
            const icons = {
                'Visa': 'pi pi-credit-card',
                'Mastercard': 'pi pi-credit-card',
                'American Express': 'pi pi-credit-card',
                'Discover': 'pi pi-credit-card'
            };
            return icons[type] || 'pi pi-credit-card';
        },
        getStatusSeverity(status) {
            const severities = {
                'Active': 'success',
                'Inactive': 'info',
                'Suspended': 'warning',
                'Expired': 'danger'
            };
            return severities[status] || 'secondary';
        }
    }
};
</script>