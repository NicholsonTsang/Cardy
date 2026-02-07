<template>
  <PageWrapper :title="$t('admin.credits.title')" :description="$t('admin.credits.description')">
    <template #actions>
      <Button 
        icon="pi pi-refresh" 
        :label="$t('admin.refresh_data')" 
        @click="refreshData"
        :loading="adminCreditStore.loading"
        severity="secondary"
        outlined
      />
    </template>

    <div class="space-y-6">
      
      <!-- System Statistics Cards -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <!-- Total Credits in Circulation -->
        <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-all duration-200">
          <div class="flex items-start gap-4">
            <div class="w-12 h-12 rounded-lg bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center shadow-lg flex-shrink-0">
              <i class="pi pi-bolt text-white text-xl"></i>
            </div>
            <div class="flex-1 min-w-0">
              <p class="text-xs font-medium text-slate-600 mb-1 truncate">{{ $t('admin.credits.totalInCirculation') }}</p>
              <h3 class="text-2xl font-bold text-slate-900 truncate">{{ systemStats?.total_credits_in_circulation?.toFixed(2) || '0.00' }}</h3>
              <div class="mt-1">
                <span class="text-xs text-slate-500 truncate block">{{ $t('admin.credits.usersWithCredits') }}: {{ systemStats?.total_users_with_credits || 0 }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Total Revenue -->
        <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-all duration-200">
          <div class="flex items-start gap-4">
            <div class="w-12 h-12 rounded-lg bg-gradient-to-br from-green-500 to-green-600 flex items-center justify-center shadow-lg flex-shrink-0">
              <i class="pi pi-dollar text-white text-xl"></i>
            </div>
            <div class="flex-1 min-w-0">
              <p class="text-xs font-medium text-slate-600 mb-1 truncate">{{ $t('admin.credits.totalRevenue') }}</p>
              <h3 class="text-2xl font-bold text-slate-900 truncate">${{ systemStats?.total_revenue_usd?.toFixed(2) || '0.00' }}</h3>
              <div class="mt-1">
                <span class="text-xs text-slate-500 truncate block">
                  {{ $t('admin.credits.monthlyPurchases') }}: ${{ systemStats?.monthly_purchases?.toFixed(2) || '0.00' }}
                </span>
              </div>
            </div>
          </div>
        </div>

        <!-- Total Purchased -->
        <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-all duration-200">
          <div class="flex items-start gap-4">
            <div class="w-12 h-12 rounded-lg bg-gradient-to-br from-purple-500 to-purple-600 flex items-center justify-center shadow-lg flex-shrink-0">
              <i class="pi pi-shopping-cart text-white text-xl"></i>
            </div>
            <div class="flex-1 min-w-0">
              <p class="text-xs font-medium text-slate-600 mb-1 truncate">{{ $t('admin.credits.totalPurchased') }}</p>
              <h3 class="text-2xl font-bold text-slate-900 truncate">{{ systemStats?.total_credits_purchased?.toFixed(2) || '0.00' }}</h3>
              <div class="mt-1">
                <span class="text-xs text-slate-500 truncate block">{{ $t('admin.credits.pendingPurchases') }}: {{ systemStats?.pending_purchases || 0 }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Total Consumed -->
        <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-all duration-200">
          <div class="flex items-start gap-4">
            <div class="w-12 h-12 rounded-lg bg-gradient-to-br from-orange-500 to-orange-600 flex items-center justify-center shadow-lg flex-shrink-0">
              <i class="pi pi-chart-line text-white text-xl"></i>
            </div>
            <div class="flex-1 min-w-0">
              <p class="text-xs font-medium text-slate-600 mb-1 truncate">{{ $t('admin.credits.totalConsumed') }}</p>
              <h3 class="text-2xl font-bold text-slate-900 truncate">{{ systemStats?.total_credits_consumed?.toFixed(2) || '0.00' }}</h3>
              <div class="mt-1">
                <span class="text-xs text-slate-500 truncate block">
                  {{ $t('admin.credits.monthlyConsumption') }}: {{ systemStats?.monthly_consumption?.toFixed(2) || '0.00' }}
                </span>
              </div>
            </div>
          </div>
        </div>
              </div>

              <!-- User Credits Table -->
              <div class="bg-white rounded-xl shadow-soft border border-slate-200 overflow-hidden">
                <div class="px-6 py-4 border-b border-slate-200">
                  <h2 class="text-lg font-semibold text-slate-900">{{ $t('admin.credits.userBalances') }}</h2>
                  <p class="text-sm text-slate-600 mt-1">{{ $t('admin.credits.description') }}</p>
                </div>
                <DataTable 
                  :value="adminCreditStore.userCredits" 
                  :loading="adminCreditStore.loading"
                  lazy
                  paginator 
                  :rows="rowsPerPage" 
                  :totalRecords="adminCreditStore.totalRecords"
                  :rowsPerPageOptions="[10, 20, 50, 100]"
                  @page="onPageChange"
                  @sort="onSort"
                  :first="first"
                  dataKey="user_id"
                  showGridlines
                  stripedRows
                  sortMode="single"
                  removableSort
                  responsiveLayout="scroll"
                >
                  <template #header>
                    <div class="flex flex-col gap-4">
                      <div class="flex justify-between items-center">
                        <span class="text-sm text-slate-600">
                          {{ $t('common.total') || 'Total' }}: {{ adminCreditStore.totalRecords || 0 }}
                        </span>
                      </div>
                      
                      <!-- Filters -->
                      <div class="flex flex-wrap gap-3 items-center">
                        <div class="flex items-center gap-2">
                          <label class="text-sm text-slate-700 font-medium">{{ $t('admin.search_by_email') }}</label>
                          <InputText 
                            v-model="userFilter"
                            :placeholder="$t('admin.search_by_email')"
                            class="w-64"
                          />
                        </div>
                        
                        <Button 
                          icon="pi pi-times"
                          :label="$t('admin.clear_filters') || 'Clear Filters'"
                          @click="clearSearch"
                          size="small"
                          severity="secondary"
                          outlined
                          v-if="userFilter"
                        />
                      </div>
                    </div>
                  </template>

                  <template #empty>
                    <div class="text-center py-12">
                      <i class="pi pi-inbox text-6xl text-slate-400 mb-4"></i>
                      <p class="text-lg font-medium text-slate-900 mb-2">{{ $t('admin.no_users_found') }}</p>
                      <p class="text-slate-600">
                        {{ userFilter ? $t('admin.credits.noUsersMatchFilters') : $t('admin.credits.noUsersWithCreditsYet') }}
                      </p>
                    </div>
                  </template>
                  <template #loading>
                    <div class="flex items-center justify-center py-12">
                      <ProgressSpinner style="width: 50px; height: 50px" strokeWidth="4" />
                    </div>
                  </template>
                  
                  <Column field="user_name" :header="$t('common.user')" :sortable="true" style="min-width: 200px">
                    <template #body="{ data }">
                      <span class="font-medium text-slate-900">{{ data.user_name }}</span>
                    </template>
                  </Column>
                  <Column field="user_email" :header="$t('common.email')" :sortable="true" style="min-width: 250px">
                    <template #body="{ data }">
                      <span class="text-slate-600">{{ data.user_email }}</span>
                    </template>
                  </Column>
                  <Column field="balance" :header="$t('admin.credits.currentBalance')" :sortable="true" style="min-width: 150px">
                    <template #body="{ data }">
                      <Chip :label="data.balance.toFixed(2)" icon="pi pi-wallet" severity="success" />
                    </template>
                  </Column>
                  <Column field="total_purchased" :header="$t('admin.credits.totalPurchased')" :sortable="true" style="min-width: 160px">
                    <template #body="{ data }">
                      <span class="font-semibold text-slate-900">{{ data.total_purchased.toFixed(2) }}</span>
                    </template>
                  </Column>
                  <Column field="total_consumed" :header="$t('admin.credits.totalConsumed')" :sortable="true" style="min-width: 160px">
                    <template #body="{ data }">
                      <span class="text-slate-600">{{ data.total_consumed.toFixed(2) }}</span>
                    </template>
                  </Column>
                  <Column field="created_at" :header="$t('common.createdAt')" :sortable="true" style="min-width: 180px">
                    <template #body="{ data }">
                      <span class="text-sm text-slate-600">{{ formatDate(data.created_at) }}</span>
                    </template>
                  </Column>
                  <Column :header="$t('common.actions')" :style="{ width: '220px', minWidth: '220px' }" frozen alignFrozen="right">
                    <template #body="{ data }">
                      <div class="flex items-center gap-2">
                        <Button
                          icon="pi pi-shopping-cart"
                          size="small"
                          rounded
                          outlined
                          severity="primary"
                          @click="viewUserPurchases(data)"
                          v-tooltip.top="$t('admin.credits.viewPurchases')"
                          class="action-btn"
                        />
                        <Button
                          icon="pi pi-chart-line"
                          size="small"
                          rounded
                          outlined
                          severity="info"
                          @click="viewUserConsumptions(data)"
                          v-tooltip.top="$t('admin.credits.viewConsumptions')"
                          class="action-btn"
                        />
                        <Button
                          icon="pi pi-list"
                          size="small"
                          rounded
                          outlined
                          severity="secondary"
                          @click="viewUserTransactions(data)"
                          v-tooltip.top="$t('admin.credits.viewTransactions')"
                          class="action-btn"
                        />
                        <Button
                          icon="pi pi-pencil"
                          size="small"
                          rounded
                          outlined
                          severity="warning"
                          @click="openAdjustDialog(data)"
                          v-tooltip.top="$t('admin.credits.adjustBalance')"
                          class="action-btn"
                        />
                      </div>
                    </template>
                  </Column>
                </DataTable>
              </div>
            </div>
          </PageWrapper>

          <!-- View Purchases Dialog -->
          <Dialog 
            v-model:visible="showPurchasesDialog"
            modal
            :header="$t('admin.credits.purchasesFor', { name: viewingUser?.user_name })"
            :style="{ width: '90vw', maxWidth: '1200px' }"
            :dismissableMask="true"
          >
            <div class="mb-4 p-4 bg-blue-50 border border-blue-200 rounded-lg">
              <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-full bg-blue-500 flex items-center justify-center">
                  <i class="pi pi-user text-white"></i>
                </div>
                <div>
                  <p class="font-semibold text-slate-900">{{ viewingUser?.user_name }}</p>
                  <p class="text-sm text-slate-600">{{ viewingUser?.user_email }}</p>
                </div>
              </div>
            </div>
                        <DataTable 
                          :value="adminCreditStore.purchases" 
                          :loading="adminCreditStore.loading"
                          paginator 
                          :rows="20" 
                          :rowsPerPageOptions="[20, 50, 100]"
                          showGridlines
                          responsiveLayout="scroll"
                        >
                          <template #empty>
                            <div class="text-center py-12">
                              <i class="pi pi-shopping-bag text-6xl text-slate-400 mb-4"></i>
                              <p class="text-lg font-medium text-slate-900 mb-2">{{ $t('admin.credits.noPurchasesFound') }}</p>
                              <p class="text-slate-600">{{ $t('admin.credits.noPurchasesYet') }}</p>
                            </div>
                          </template>
                  <template #loading>
                    <div class="flex items-center justify-center py-12">
                      <ProgressSpinner style="width: 50px; height: 50px" strokeWidth="4" />
                    </div>
                  </template>
                  
                  <Column field="created_at" :header="$t('common.date')" sortable style="min-width: 180px">
                    <template #body="{ data }">
                      <span class="text-sm text-slate-600">{{ formatDate(data.created_at) }}</span>
                    </template>
                  </Column>
                  <Column field="user_name" :header="$t('common.user')" sortable style="min-width: 200px">
                    <template #body="{ data }">
                      <span class="font-medium text-slate-900">{{ data.user_name }}</span>
                    </template>
                  </Column>
                  <Column field="user_email" :header="$t('common.email')" style="min-width: 250px">
                    <template #body="{ data }">
                      <span class="text-slate-600">{{ data.user_email }}</span>
                    </template>
                  </Column>
                  <Column field="credits_amount" :header="$t('admin.credits.creditsAmount')" sortable style="min-width: 140px">
                    <template #body="{ data }">
                      <Chip :label="data.credits_amount.toFixed(2)" icon="pi pi-bolt" severity="success" />
                    </template>
                  </Column>
                  <Column field="amount_usd" :header="$t('admin.credits.amountUSD')" sortable style="min-width: 130px">
                    <template #body="{ data }">
                      <div class="flex items-center gap-2 font-semibold text-base">
                        <i class="pi pi-dollar text-green-600"></i>
                        <span>${{ data.amount_usd.toFixed(2) }}</span>
                      </div>
                    </template>
                  </Column>
                  <Column field="status" :header="$t('common.status')" style="min-width: 130px">
                    <template #body="{ data }">
                      <Tag :severity="getPurchaseStatusSeverity(data.status)" :value="$t(`credits.status.${data.status}`)" :icon="getPurchaseStatusIcon(data.status)"/>
                    </template>
                  </Column>
                  <Column field="stripe_session_id" :header="$t('admin.credits.stripeSession')" style="min-width: 220px">
                    <template #body="{ data }">
                      <span class="text-xs font-mono text-slate-500">{{ data.stripe_session_id?.substring(0, 30) }}...</span>
                    </template>
                  </Column>
                  <Column field="receipt_url" :header="$t('admin.credits.receipt')" style="min-width: 100px">
                    <template #body="{ data }">
                      <Button 
                        v-if="data.receipt_url" 
                        icon="pi pi-file-pdf" 
                        :label="$t('common.receipt')"
                        text 
                        size="small"
                        severity="secondary"
                        @click="openReceipt(data.receipt_url)"
                      />
                      <span v-else class="text-slate-400 text-sm">-</span>
                    </template>
                  </Column>
                </DataTable>
          </Dialog>

          <!-- View Consumptions Dialog -->
          <Dialog 
            v-model:visible="showConsumptionsDialog"
            modal
            :header="$t('admin.credits.consumptionsFor', { name: viewingUser?.user_name })"
            :style="{ width: '90vw', maxWidth: '1200px' }"
            :dismissableMask="true"
          >
            <div class="mb-4 p-4 bg-blue-50 border border-blue-200 rounded-lg">
              <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-full bg-blue-500 flex items-center justify-center">
                  <i class="pi pi-user text-white"></i>
                </div>
                <div>
                  <p class="font-semibold text-slate-900">{{ viewingUser?.user_name }}</p>
                  <p class="text-sm text-slate-600">{{ viewingUser?.user_email }}</p>
                </div>
              </div>
            </div>
                        <DataTable 
                          :value="adminCreditStore.consumptions" 
                          :loading="adminCreditStore.loading"
                          paginator 
                          :rows="20" 
                          :rowsPerPageOptions="[20, 50, 100]"
                          showGridlines
                          responsiveLayout="scroll"
                        >
                          <template #empty>
                            <div class="text-center py-12">
                              <i class="pi pi-chart-bar text-6xl text-slate-400 mb-4"></i>
                              <p class="text-lg font-medium text-slate-900 mb-2">{{ $t('admin.credits.noConsumptionsFound') }}</p>
                              <p class="text-slate-600">{{ $t('admin.credits.noConsumptionsYet') }}</p>
                            </div>
                          </template>
                  <template #loading>
                    <div class="flex items-center justify-center py-12">
                      <ProgressSpinner style="width: 50px; height: 50px" strokeWidth="4" />
                    </div>
                  </template>
                  
                  <Column field="created_at" :header="$t('common.date')" sortable style="min-width: 180px">
                    <template #body="{ data }">
                      <span class="text-sm text-slate-600">{{ formatDate(data.created_at) }}</span>
                    </template>
                  </Column>
                  <Column field="user_name" :header="$t('common.user')" sortable style="min-width: 200px">
                    <template #body="{ data }">
                      <span class="font-medium text-slate-900">{{ data.user_name }}</span>
                    </template>
                  </Column>
                  <Column field="consumption_type" :header="$t('common.type')" sortable style="min-width: 180px">
                    <template #body="{ data }">
                      <Tag 
                        :value="getConsumptionTypeLabel(data.consumption_type)" 
                        :icon="getConsumptionTypeIcon(data.consumption_type)" 
                        :severity="getConsumptionTypeSeverity(data.consumption_type)" 
                      />
                    </template>
                  </Column>
                  <Column field="card_name" :header="$t('common.card')" style="min-width: 200px">
                    <template #body="{ data }">
                      <div class="flex items-center gap-2">
                        <i class="pi pi-id-card text-blue-500"></i>
                        <span class="text-slate-600">{{ data.card_name || '-' }}</span>
                      </div>
                    </template>
                  </Column>
                  <Column field="batch_name" :header="$t('batch.batch')" style="min-width: 200px">
                    <template #body="{ data }">
                      <span class="text-slate-600">{{ data.batch_name || '-' }}</span>
                    </template>
                  </Column>
                  <Column field="quantity" :header="$t('common.quantity')" sortable style="min-width: 140px">
                    <template #body="{ data }">
                      <Chip 
                        :label="`${data.quantity} ${getQuantityUnit(data.consumption_type)}`" 
                        icon="pi pi-hashtag" 
                      />
                    </template>
                  </Column>
                  <Column field="total_credits" :header="$t('admin.credits.creditsUsed')" sortable style="min-width: 140px">
                    <template #body="{ data }">
                      <div class="flex items-center gap-2 font-semibold text-base text-red-600">
                        <i class="pi pi-minus-circle"></i>
                        <span>{{ data.total_credits.toFixed(2) }}</span>
                      </div>
                    </template>
                  </Column>
                  <Column field="description" :header="$t('common.description')" style="min-width: 250px">
                    <template #body="{ data }">
                      <span class="text-slate-600">{{ data.description || '-' }}</span>
                    </template>
                  </Column>
                </DataTable>
          </Dialog>

          <!-- View Transactions Dialog -->
          <Dialog 
            v-model:visible="showTransactionsDialog"
            modal
            :header="$t('admin.credits.transactionsFor', { name: viewingUser?.user_name })"
            :style="{ width: '90vw', maxWidth: '1200px' }"
            :dismissableMask="true"
          >
            <div class="mb-4 p-4 bg-blue-50 border border-blue-200 rounded-lg">
              <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-full bg-blue-500 flex items-center justify-center">
                  <i class="pi pi-user text-white"></i>
                </div>
                <div>
                  <p class="font-semibold text-slate-900">{{ viewingUser?.user_name }}</p>
                  <p class="text-sm text-slate-600">{{ viewingUser?.user_email }}</p>
                </div>
              </div>
            </div>
                        <DataTable 
                          :value="adminCreditStore.transactions" 
                          :loading="adminCreditStore.loading"
                          paginator 
                          :rows="20" 
                          :rowsPerPageOptions="[20, 50, 100]"
                          showGridlines
                          responsiveLayout="scroll"
                        >
                          <template #empty>
                            <div class="text-center py-12">
                              <i class="pi pi-inbox text-6xl text-slate-400 mb-4"></i>
                              <p class="text-lg font-medium text-slate-900 mb-2">{{ $t('admin.credits.noTransactionsFound') }}</p>
                              <p class="text-slate-600">{{ $t('admin.credits.noTransactionsYet') }}</p>
                            </div>
                          </template>
                  <template #loading>
                    <div class="flex items-center justify-center py-12">
                      <ProgressSpinner style="width: 50px; height: 50px" strokeWidth="4" />
                    </div>
                  </template>
                  
                  <Column field="created_at" :header="$t('common.date')" sortable style="min-width: 180px">
                    <template #body="{ data }">
                      <span class="text-sm text-slate-600">{{ formatDate(data.created_at) }}</span>
                    </template>
                  </Column>
                  <Column field="user_name" :header="$t('common.user')" sortable style="min-width: 200px">
                    <template #body="{ data }">
                      <span class="font-medium text-slate-900">{{ data.user_name }}</span>
                    </template>
                  </Column>
                  <Column field="type" :header="$t('common.type')" style="min-width: 140px">
                    <template #body="{ data }">
                      <Tag :severity="getTransactionTypeSeverity(data.type)" :value="$t(`credits.type.${data.type}`)" :icon="getTransactionTypeIcon(data.type)"/>
                    </template>
                  </Column>
                  <Column field="amount" :header="$t('admin.credits.amount')" sortable style="min-width: 130px">
                    <template #body="{ data }">
                      <div class="flex items-center gap-2 font-semibold text-base">
                        <i :class="['purchase', 'adjustment'].includes(data.type) ? 'pi pi-plus-circle text-green-600' : 'pi pi-minus-circle text-red-600'"></i>
                        <span :class="['purchase', 'adjustment'].includes(data.type) ? 'text-green-600' : 'text-red-600'">
                          {{ ['purchase', 'adjustment'].includes(data.type) ? '+' : '-' }}{{ data.amount.toFixed(2) }}
                        </span>
                      </div>
                    </template>
                  </Column>
                  <Column field="balance_before" :header="$t('admin.credits.balanceBefore')" style="min-width: 140px">
                    <template #body="{ data }">
                      <span class="text-slate-600">{{ data.balance_before.toFixed(2) }}</span>
                    </template>
                  </Column>
                  <Column field="balance_after" :header="$t('admin.credits.balanceAfter')" sortable style="min-width: 140px">
                    <template #body="{ data }">
                      <Chip :label="data.balance_after.toFixed(2)" icon="pi pi-wallet" />
                    </template>
                  </Column>
                  <Column field="description" :header="$t('common.description')" style="min-width: 250px">
                    <template #body="{ data }">
                      <span class="text-slate-600">{{ data.description || '-' }}</span>
                    </template>
                  </Column>
                </DataTable>
          </Dialog>

          <!-- Adjust Credits Dialog -->
  <Dialog 
    v-model:visible="showAdjustDialog" 
    modal 
    :closable="!adjustLoading"
    :style="{ width: '600px' }"
    class="adjust-dialog"
  >
    <template #header>
      <div class="flex items-center gap-3">
        <div class="p-3 bg-orange-50 rounded-full">
          <i class="pi pi-wrench text-2xl text-orange-600"></i>
        </div>
        <div>
          <h3 class="text-xl font-bold text-slate-900">{{ $t('admin.credits.adjustUserCredits') }}</h3>
          <p class="text-sm text-slate-500 mt-1">{{ $t('admin.credits.modifyUserBalance') }}</p>
        </div>
      </div>
    </template>

    <div class="space-y-6 py-4">
      <div v-if="selectedUser" class="p-4 bg-slate-50 rounded-lg border border-slate-200">
        <label class="block text-xs font-semibold text-slate-700 mb-2 uppercase tracking-wide">{{ $t('common.user') }}</label>
        <div class="font-semibold text-slate-900 mb-1">{{ selectedUser.user_name }}</div>
        <div class="text-sm text-slate-600 mb-3">{{ selectedUser.user_email }}</div>
        <div class="flex items-center gap-2 text-sm">
          <span class="text-slate-600">{{ $t('admin.credits.currentBalance') }}:</span>
          <Chip :label="selectedUser.balance.toFixed(2)" icon="pi pi-wallet" severity="success" />
        </div>
      </div>

      <div>
        <label class="block text-sm font-semibold text-slate-700 mb-3">
          {{ $t('admin.credits.adjustmentAmount') }} *
        </label>
        <InputNumber 
          v-model="adjustAmount" 
          :min="-10000" 
          :max="10000"
          :step="10"
          :placeholder="$t('admin.credits.enterAmount')"
          class="w-full"
          size="large"
        />
        <small class="text-slate-500 mt-2 block">
          {{ $t('admin.credits.positiveToAdd') }}
        </small>
      </div>

      <div>
        <label class="block text-sm font-semibold text-slate-700 mb-3">
          {{ $t('admin.credits.reason') }} *
        </label>
        <Textarea 
          v-model="adjustReason" 
          rows="4" 
          :placeholder="$t('admin.credits.enterReason')"
          class="w-full"
        />
      </div>

      <div v-if="adjustAmount && selectedUser" class="p-4 rounded-lg border-2" :class="adjustAmount > 0 ? 'bg-green-50 border-green-200' : 'bg-red-50 border-red-200'">
        <div class="flex items-center justify-between">
          <span class="text-sm font-medium" :class="adjustAmount > 0 ? 'text-green-800' : 'text-red-800'">
            {{ $t('admin.credits.newBalance') }}:
          </span>
          <div class="flex items-center gap-2">
            <i :class="['pi text-xl', adjustAmount > 0 ? 'pi-arrow-up text-green-600' : 'pi-arrow-down text-red-600']"></i>
            <span class="text-2xl font-bold" :class="adjustAmount > 0 ? 'text-green-700' : 'text-red-700'">
              {{ ((selectedUser?.balance || 0) + (adjustAmount || 0)).toFixed(2) }}
            </span>
          </div>
        </div>
        <div class="mt-2 text-xs" :class="adjustAmount > 0 ? 'text-green-700' : 'text-red-700'">
          {{ adjustAmount > 0 ? '+' : '' }}{{ adjustAmount }} {{ $t('common.credits') }}
        </div>
      </div>
    </div>

    <template #footer>
      <div class="flex justify-between items-center w-full">
        <Button 
          :label="$t('common.cancel')" 
          @click="closeAdjustDialog" 
          text 
          size="large"
          :disabled="adjustLoading"
        />
        <Button 
          :label="$t('admin.credits.confirmAdjustment')" 
          @click="confirmAdjustment" 
          :disabled="!adjustAmount || !adjustReason || adjustLoading"
          :loading="adjustLoading"
          severity="warning"
          icon="pi pi-check"
          size="large"
        />
      </div>
    </template>
  </Dialog>
</template>

<script setup lang="ts">
import { ref, onMounted, computed, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useAdminCreditStore } from '@/stores/admin/credits'
import { useToast } from 'primevue/usetoast'
import Button from 'primevue/button'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import Dialog from 'primevue/dialog'
import Tag from 'primevue/tag'
import InputText from 'primevue/inputtext'
import InputNumber from 'primevue/inputnumber'
import Textarea from 'primevue/textarea'
import Chip from 'primevue/chip'
import ProgressSpinner from 'primevue/progressspinner'
import PageWrapper from '@/components/Layout/PageWrapper.vue'
import { formatDate } from '@/utils/formatters'

const { t } = useI18n()
const toast = useToast()
const adminCreditStore = useAdminCreditStore()

const userFilter = ref('')

// Dialog states
const showPurchasesDialog = ref(false)
const showConsumptionsDialog = ref(false)
const showTransactionsDialog = ref(false)
const showAdjustDialog = ref(false)

// Selected/viewing user
const viewingUser = ref<any>(null)
const selectedUser = ref<any>(null)

// Adjust credits form
const adjustAmount = ref<number | null>(null)
const adjustReason = ref('')
const adjustLoading = ref(false)

// Pagination state
const first = ref(0)
const rowsPerPage = ref(20)
const sortField = ref('balance')
const sortOrder = ref<'ASC' | 'DESC'>('DESC')

const systemStats = computed(() => adminCreditStore.systemStats)

// Debounced search function
let searchTimeout: NodeJS.Timeout | null = null
watch(userFilter, (newValue) => {
  if (searchTimeout) clearTimeout(searchTimeout)
  
  // Debounce the search
  searchTimeout = setTimeout(async () => {
    first.value = 0 // Reset to first page when searching
    await loadUserCredits()
  }, 500)
})

// Load user credits with current pagination and filters
async function loadUserCredits() {
  await adminCreditStore.fetchUserCredits(
    rowsPerPage.value,
    first.value,
    userFilter.value || undefined,
    sortField.value,
    sortOrder.value
  )
}

// Refresh data
async function refreshData() {
  await Promise.all([
    adminCreditStore.fetchSystemStatistics(),
    loadUserCredits()
  ])
}

// Clear search and reset
function clearSearch() {
  userFilter.value = ''
  first.value = 0
  loadUserCredits()
}

// Dialog functions
async function viewUserPurchases(user: any) {
  viewingUser.value = user
  showPurchasesDialog.value = true
  await adminCreditStore.fetchCreditPurchases(100, 0, user.user_id)
}

async function viewUserConsumptions(user: any) {
  viewingUser.value = user
  showConsumptionsDialog.value = true
  await adminCreditStore.fetchCreditConsumptions(100, 0, user.user_id)
}

async function viewUserTransactions(user: any) {
  viewingUser.value = user
  showTransactionsDialog.value = true
  await adminCreditStore.fetchCreditTransactions(100, 0, user.user_id)
}

// Handle page change
function onPageChange(event: any) {
  first.value = event.first
  rowsPerPage.value = event.rows
  loadUserCredits()
}

// Handle sort
function onSort(event: any) {
  sortField.value = event.sortField || 'balance'
  sortOrder.value = event.sortOrder === 1 ? 'ASC' : 'DESC'
  loadUserCredits()
}

onMounted(async () => {
  await refreshData()
})

function getTransactionTypeSeverity(type: string) {
  switch (type) {
    case 'purchase': return 'success'
    case 'consumption': return 'danger'
    case 'refund': return 'warn'
    case 'adjustment': return 'info'
    default: return undefined
  }
}

function getTransactionTypeIcon(type: string) {
  switch (type) {
    case 'purchase': return 'pi-shopping-cart'
    case 'consumption': return 'pi-arrow-down'
    case 'refund': return 'pi-replay'
    case 'adjustment': return 'pi-wrench'
    default: return 'pi-circle'
  }
}

function getPurchaseStatusSeverity(status: string) {
  switch (status) {
    case 'completed': return 'success'
    case 'pending': return 'warn'
    case 'failed': return 'danger'
    case 'refunded': return 'info'
    default: return undefined
  }
}

function getPurchaseStatusIcon(status: string) {
  switch (status) {
    case 'completed': return 'pi-check-circle'
    case 'pending': return 'pi-clock'
    case 'failed': return 'pi-times-circle'
    case 'refunded': return 'pi-replay'
    default: return 'pi-circle'
  }
}

function getConsumptionTypeLabel(type: string) {
  const { t } = useI18n()
  const key = `credits.consumptionType.${type}`
  // Try to get translation, fallback to type or 'Unknown'
  return t(key, type || 'Unknown')
}

function getConsumptionTypeIcon(type: string) {
  switch (type) {
    case 'subscription_overage_batch': return 'pi-bolt'
    case 'batch_issuance': return 'pi-box'
    case 'translation': return 'pi-language'
    case 'single_card': return 'pi-id-card'
    case 'digital_scan': return 'pi-qrcode'
    default: return 'pi-circle'
  }
}

function getConsumptionTypeSeverity(type: string) {
  switch (type) {
    case 'subscription_overage_batch': return 'warn'
    case 'batch_issuance': return 'info'
    case 'translation': return 'success'
    case 'single_card': return 'info'
    case 'digital_scan': return 'secondary'
    default: return undefined
  }
}

function getQuantityUnit(type: string) {
  switch (type) {
    case 'subscription_overage_batch': return t('credits.unit.access')
    case 'batch_issuance': return t('credits.unit.cards')
    case 'translation': return t('credits.unit.languages')
    case 'single_card': return t('credits.unit.cards')
    case 'digital_scan': return t('credits.unit.scans')
    default: return t('credits.unit.units')
  }
}

function openReceipt(url: string) {
  window.open(url, '_blank')
}

function openAdjustDialog(user: any) {
  selectedUser.value = user
  adjustAmount.value = null
  adjustReason.value = ''
  showAdjustDialog.value = true
}

function closeAdjustDialog() {
  showAdjustDialog.value = false
  selectedUser.value = null
  adjustAmount.value = null
  adjustReason.value = ''
}

async function confirmAdjustment() {
  if (!selectedUser.value || !adjustAmount.value || !adjustReason.value) return

  adjustLoading.value = true
  try {
    await adminCreditStore.adjustUserCredits(
      selectedUser.value.user_id,
      adjustAmount.value,
      adjustReason.value
    )
    
    toast.add({
      severity: 'success',
      summary: t('common.success'),
      detail: t('admin.credits.adjustmentSuccess'),
      life: 3000
    })
    
    closeAdjustDialog()
    
    // Refresh data
    await Promise.all([
      adminCreditStore.fetchSystemStatistics(),
      loadUserCredits()
    ])
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: error.message || t('admin.credits.adjustmentError'),
      life: 5000
    })
  } finally {
    adjustLoading.value = false
  }
}
</script>

<style scoped>
/* Component-specific styles - global table theme now handles standard styling */

:deep(.p-datatable .p-datatable-tbody > tr:hover) {
  background-color: #f8fafc;
}

/* Action Button Styles */
.action-btn {
  transition: all 0.2s ease;
}

.action-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
}

.action-btn:active {
  transform: translateY(0);
}

/* Ensure action buttons are aligned to left within their frozen column */
:deep(.p-datatable .p-datatable-tbody > tr > td:last-child) {
  text-align: left !important;
}

:deep(.p-datatable .p-datatable-thead > tr > th:last-child) {
  text-align: left !important;
}
</style>
