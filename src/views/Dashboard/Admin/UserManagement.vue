<template>
  <PageWrapper :title="$t('admin.user_management')" :description="$t('admin.view_manage_users')">
    <template #actions>
      <Button 
        icon="pi pi-refresh" 
        :label="$t('admin.refresh_data')" 
        severity="secondary"
        outlined
        @click="refreshData"
        :loading="isLoading"
      />
      <Button 
        icon="pi pi-download" 
        :label="$t('admin.export_csv')" 
        severity="secondary"
        outlined
        @click="exportUsers"
      />
    </template>

    <div class="space-y-6">
      <!-- Statistics Cards -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div class="bg-white rounded-xl shadow-soft border border-slate-200 p-5 hover:shadow-medium transition-shadow duration-200">
          <div class="flex items-center justify-between">
            <div>
              <h3 class="text-sm font-medium text-slate-600 mb-1">{{ $t('admin.total_users') }}</h3>
              <p class="text-2xl font-bold text-slate-900">{{ userStats.total }}</p>
            </div>
            <div class="p-3 bg-gradient-to-r from-blue-500 to-indigo-500 rounded-xl">
              <i class="pi pi-users text-white text-xl"></i>
            </div>
          </div>
        </div>

        <div class="bg-white rounded-xl shadow-soft border border-slate-200 p-5 hover:shadow-medium transition-shadow duration-200">
          <div class="flex items-center justify-between">
            <div>
              <h3 class="text-sm font-medium text-slate-600 mb-1">{{ $t('admin.card_issuers') }}</h3>
              <p class="text-2xl font-bold text-slate-900">{{ userStats.cardIssuers }}</p>
            </div>
            <div class="p-3 bg-gradient-to-r from-green-500 to-green-600 rounded-xl">
              <i class="pi pi-id-card text-white text-xl"></i>
            </div>
          </div>
        </div>

        <div class="bg-white rounded-xl shadow-soft border border-slate-200 p-5 hover:shadow-medium transition-shadow duration-200">
          <div class="flex items-center justify-between">
            <div>
              <h3 class="text-sm font-medium text-slate-600 mb-1">{{ $t('admin.admins') }}</h3>
              <p class="text-2xl font-bold text-slate-900">{{ userStats.admins }}</p>
            </div>
            <div class="p-3 bg-gradient-to-r from-purple-500 to-violet-500 rounded-xl">
              <i class="pi pi-shield text-white text-xl"></i>
            </div>
          </div>
        </div>
      </div>

      <!-- Subscription Tier Stats -->
      <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div class="bg-white rounded-xl shadow-soft border border-slate-200 p-5 hover:shadow-medium transition-shadow duration-200">
          <div class="flex items-center justify-between">
            <div>
              <h3 class="text-sm font-medium text-slate-600 mb-1">{{ $t('admin.enterprise_users') }}</h3>
              <p class="text-2xl font-bold text-violet-600">{{ userStats.enterpriseUsers }}</p>
            </div>
            <div class="p-3 bg-gradient-to-r from-violet-500 to-purple-500 rounded-xl">
              <i class="pi pi-building text-white text-xl"></i>
            </div>
          </div>
        </div>

        <div class="bg-white rounded-xl shadow-soft border border-slate-200 p-5 hover:shadow-medium transition-shadow duration-200">
          <div class="flex items-center justify-between">
            <div>
              <h3 class="text-sm font-medium text-slate-600 mb-1">{{ $t('admin.premium_users') }}</h3>
              <p class="text-2xl font-bold text-amber-600">{{ userStats.premiumUsers }}</p>
            </div>
            <div class="p-3 bg-gradient-to-r from-amber-500 to-orange-500 rounded-xl">
              <i class="pi pi-star-fill text-white text-xl"></i>
            </div>
          </div>
        </div>

        <div class="bg-white rounded-xl shadow-soft border border-slate-200 p-5 hover:shadow-medium transition-shadow duration-200">
          <div class="flex items-center justify-between">
            <div>
              <h3 class="text-sm font-medium text-slate-600 mb-1">{{ $t('admin.starter_users') }}</h3>
              <p class="text-2xl font-bold text-emerald-600">{{ userStats.starterUsers }}</p>
            </div>
            <div class="p-3 bg-gradient-to-r from-emerald-500 to-teal-500 rounded-xl">
              <i class="pi pi-bolt text-white text-xl"></i>
            </div>
          </div>
        </div>

        <div class="bg-white rounded-xl shadow-soft border border-slate-200 p-5 hover:shadow-medium transition-shadow duration-200">
          <div class="flex items-center justify-between">
            <div>
              <h3 class="text-sm font-medium text-slate-600 mb-1">{{ $t('admin.free_users') }}</h3>
              <p class="text-2xl font-bold text-slate-700">{{ userStats.freeUsers }}</p>
            </div>
            <div class="p-3 bg-gradient-to-r from-slate-400 to-slate-500 rounded-xl">
              <i class="pi pi-user text-white text-xl"></i>
            </div>
          </div>
        </div>
      </div>

      <!-- Filters and Search -->
      <div class="bg-white rounded-xl shadow-soft border border-slate-200 p-6">
        <h3 class="text-lg font-semibold text-slate-900 mb-4">{{ $t('admin.filters_search') || 'Filters & Search' }}</h3>
        <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div class="md:col-span-2">
            <IconField>
              <InputIcon class="pi pi-search" />
              <InputText 
                v-model="searchQuery"
                :placeholder="$t('admin.search_by_email')"
                class="w-full"
                @input="filterUsers"
              />
            </IconField>
          </div>
          <div>
            <Select 
              v-model="selectedRole"
              :options="roleOptions"
              optionLabel="label"
              optionValue="value"
              :placeholder="$t('admin.filter_by_role') || 'Filter by Role'"
              class="w-full"
              @change="filterUsers"
              showClear
            />
          </div>
          <div>
            <Select 
              v-model="selectedTier"
              :options="tierOptions"
              optionLabel="label"
              optionValue="value"
              :placeholder="$t('admin.filter_by_tier') || 'Filter by Tier'"
              class="w-full"
              @change="filterUsers"
              showClear
            />
          </div>
        </div>
        <div v-if="hasActiveFilters" class="mt-4 flex items-center justify-between">
          <span class="text-sm text-slate-600">
            {{ filteredUsers.length }} {{ $t('admin.of') || 'of' }} {{ allUsers.length }} {{ $t('admin.users_shown') || 'users shown' }}
          </span>
          <Button 
            :label="$t('admin.clear_filters')" 
            size="small"
            text
            severity="secondary"
            @click="clearFilters"
          />
        </div>
      </div>

      <!-- Users Table -->
      <div class="bg-white rounded-xl shadow-soft border border-slate-200 overflow-hidden">
        <DataTable 
          :value="paginatedUsers"
          :loading="isLoading"
          showGridlines
          :paginator="true"
          :rows="pageSize"
          :totalRecords="filteredUsers.length"
          :lazy="false"
          @page="onPageChange"
          paginatorTemplate="FirstPageLink PrevPageLink PageLinks NextPageLink LastPageLink CurrentPageReport RowsPerPageDropdown"
          :rowsPerPageOptions="[10, 20, 50, 100]"
          :currentPageReportTemplate="$t('admin.current_page_report') || 'Showing {first} to {last} of {totalRecords} users'"
          class="users-table"
          responsiveLayout="scroll"
          :scrollable="true"
          scrollHeight="flex"
        >
          <Column field="user_email" :header="$t('admin.user_email')" sortable :style="{ width: '280px', minWidth: '250px' }" frozen>
            <template #body="{ data }">
              <div class="flex items-center gap-2">
                <div class="w-8 h-8 bg-gradient-to-r from-blue-500 to-indigo-500 rounded-full flex items-center justify-center text-white text-xs font-medium flex-shrink-0">
                  {{ data.user_email.charAt(0).toUpperCase() }}
                </div>
                <span class="font-medium text-slate-900 truncate">{{ data.user_email }}</span>
              </div>
            </template>
          </Column>

          <Column field="role" :header="$t('admin.user_role')" sortable :style="{ width: '140px', minWidth: '140px' }">
            <template #body="{ data }">
              <Tag 
                :value="getRoleLabel(data.role)"
                :severity="getRoleSeverity(data.role)"
                class="whitespace-nowrap"
              />
            </template>
          </Column>

          <Column field="cards_count" :header="$t('batches.cards')" sortable :style="{ width: '100px', minWidth: '100px' }" class="text-center">
            <template #body="{ data }">
              <div class="text-center">
                <span class="inline-flex items-center justify-center px-2 py-1 text-xs font-semibold rounded-full bg-blue-100 text-blue-800">
                  {{ data.cards_count || 0 }}
                </span>
              </div>
            </template>
          </Column>

          <Column field="created_at" :header="$t('admin.registered') || 'Registered'" sortable :style="{ width: '140px', minWidth: '140px' }">
            <template #body="{ data }">
              <span class="text-sm text-slate-600 whitespace-nowrap">{{ formatDate(data.created_at) }}</span>
            </template>
          </Column>

          <Column field="subscription_tier" :header="$t('admin.subscription_tier') || 'Tier'" sortable :style="{ width: '120px', minWidth: '120px' }">
            <template #body="{ data }">
              <Tag 
                :value="getTierLabel(data.subscription_tier)"
                :severity="getTierSeverity(data.subscription_tier)"
                class="whitespace-nowrap"
              >
                <template #icon>
                  <i :class="data.subscription_tier === 'enterprise' ? 'pi pi-building mr-1' : data.subscription_tier === 'premium' ? 'pi pi-star-fill mr-1' : 'pi pi-user mr-1'" style="font-size: 0.7rem;"></i>
                </template>
              </Tag>
            </template>
          </Column>

          <Column field="subscription_status" :header="$t('admin.subscription_status') || 'Sub Status'" sortable :style="{ width: '120px', minWidth: '120px' }">
            <template #body="{ data }">
              <div class="flex items-center gap-1">
                <Tag 
                  :value="getSubscriptionStatusLabel(data)"
                  :severity="getSubscriptionStatusSeverity(data)"
                  class="whitespace-nowrap text-xs"
                />
              </div>
            </template>
          </Column>

          <Column field="stripe_subscription_id" :header="$t('admin.source') || 'Source'" :style="{ width: '110px', minWidth: '110px' }">
            <template #body="{ data }">
              <Tag 
                v-if="data.subscription_tier !== 'free'"
                :value="data.stripe_subscription_id ? ($t('admin.stripe') || 'Stripe') : ($t('admin.admin') || 'Admin')"
                :severity="data.stripe_subscription_id ? 'info' : 'secondary'"
                class="whitespace-nowrap text-xs"
              >
                <template #icon>
                  <i :class="data.stripe_subscription_id ? 'pi pi-credit-card mr-1' : 'pi pi-shield mr-1'" style="font-size: 0.6rem;"></i>
                </template>
              </Tag>
              <span v-else class="text-slate-400 text-xs">-</span>
            </template>
          </Column>

          <Column field="current_period_end" :header="$t('admin.renewal_expiry') || 'Renewal/Expiry'" sortable :style="{ width: '150px', minWidth: '150px' }">
            <template #body="{ data }">
              <div v-if="data.subscription_tier !== 'free' && data.current_period_end" class="text-xs">
                <div class="flex items-center gap-1 text-slate-700">
                  <i :class="data.stripe_subscription_id ? 'pi pi-sync' : 'pi pi-calendar'" class="text-[10px] text-slate-400"></i>
                  <span>{{ formatDate(data.current_period_end) }}</span>
                </div>
                <div v-if="isPermanentSubscription(data.current_period_end)" class="text-slate-400 text-[10px] mt-0.5">
                  {{ $t('admin.permanent') || 'Permanent' }}
                </div>
                <div v-else class="text-slate-400 text-[10px] mt-0.5">
                  {{ getDaysRemaining(data.current_period_end) }}
                </div>
              </div>
              <span v-else class="text-slate-400 text-xs">-</span>
            </template>
          </Column>

          <Column field="last_sign_in_at" :header="$t('admin.last_sign_in') || 'Last Sign In'" sortable :style="{ width: '140px', minWidth: '140px' }">
            <template #body="{ data }">
              <span class="text-sm text-slate-600 whitespace-nowrap">
                {{ data.last_sign_in_at ? formatDate(data.last_sign_in_at) : ($t('admin.never') || 'Never') }}
              </span>
            </template>
          </Column>

          <Column :header="$t('common.actions')" :style="{ width: '180px', minWidth: '180px' }" frozen alignFrozen="right" class="text-center">
            <template #body="{ data }">
              <div class="flex items-center justify-center gap-1">
                <Button
                  icon="pi pi-cog"
                  size="small"
                  outlined
                  severity="secondary"
                  @click="manageUserRole(data)"
                  v-tooltip.top="$t('admin.manage_role')"
                />
                <Button
                  icon="pi pi-star"
                  size="small"
                  outlined
                  :severity="data.subscription_tier === 'enterprise' ? 'contrast' : data.subscription_tier === 'premium' ? 'warning' : 'info'"
                  @click="manageUserSubscription(data)"
                  v-tooltip.top="$t('admin.manage_subscription') || 'Manage Subscription'"
                />
                <Button
                  icon="pi pi-folder-open"
                  size="small"
                  outlined
                  severity="secondary"
                  @click="viewUserProjects(data)"
                  v-tooltip.top="$t('admin.view_user_projects') || 'View Projects'"
                />
              </div>
            </template>
          </Column>
        </DataTable>
      </div>

      <!-- Role Management Dialog -->
      <Dialog 
        v-model:visible="showRoleDialog"
        modal
        :header="$t('admin.manage_user_role') || 'Manage User Role'"
        :style="{ width: '90vw', maxWidth: '52rem' }"
        @hide="closeRoleDialog"
      >
        <div v-if="selectedUser" class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-slate-700 mb-2">{{ $t('admin.user') || 'User' }}</label>
            <div class="p-3 bg-slate-50 rounded-lg">
              <p class="font-medium text-slate-900">{{ selectedUser.user_email }}</p>
              <p class="text-sm text-slate-600">{{ $t('admin.current_role') || 'Current Role' }}: {{ getRoleLabel(selectedUser.role) }}</p>
            </div>
          </div>

          <div>
            <label for="newRole" class="block text-sm font-medium text-slate-700 mb-2">
              {{ $t('admin.new_role') || 'New Role' }} <span class="text-red-500">*</span>
            </label>
            <Select 
              id="newRole"
              v-model="newUserRole"
              :options="roleChangeOptions"
              optionLabel="label"
              optionValue="value"
              :placeholder="$t('admin.select_new_role') || 'Select new role'"
              class="w-full"
            />
          </div>

          <div>
            <label for="reason" class="block text-sm font-medium text-slate-700 mb-2">
              {{ $t('admin.reason_for_change') || 'Reason for Change' }} <span class="text-red-500">*</span>
            </label>
            <Textarea 
              id="reason"
              v-model="roleChangeReason"
              rows="3"
              :placeholder="$t('admin.reason_placeholder') || 'Explain why this role change is necessary...'"
              class="w-full"
            />
          </div>
        </div>

        <template #footer>
          <Button :label="$t('common.cancel')" text severity="secondary" @click="closeRoleDialog" />
          <Button 
            :label="$t('admin.update_role') || 'Update Role'" 
            severity="primary"
            @click="updateUserRole"
            :disabled="!newUserRole || !roleChangeReason"
          />
        </template>
      </Dialog>

      <!-- Subscription Management Dialog -->
      <Dialog 
        v-model:visible="showSubscriptionDialog"
        modal
        :header="$t('admin.manage_subscription') || 'Manage Subscription'"
        :style="{ width: '90vw', maxWidth: '52rem' }"
        @hide="closeSubscriptionDialog"
      >
        <div v-if="selectedUser" class="space-y-4">
          <!-- User Info -->
          <div>
            <label class="block text-sm font-medium text-slate-700 mb-2">{{ $t('admin.user') || 'User' }}</label>
            <div class="p-3 bg-slate-50 rounded-lg">
              <p class="font-medium text-slate-900">{{ selectedUser.user_email }}</p>
              <div class="flex items-center flex-wrap gap-2 mt-1">
                <Tag 
                  :value="getTierLabel(selectedUser.subscription_tier)"
                  :severity="getTierSeverity(selectedUser.subscription_tier)"
                  size="small"
                >
                  <template #icon>
                    <i :class="selectedUser.subscription_tier === 'enterprise' ? 'pi pi-building mr-1' : selectedUser.subscription_tier === 'premium' ? 'pi pi-star-fill mr-1' : 'pi pi-user mr-1'" style="font-size: 0.65rem;"></i>
                  </template>
                </Tag>
                <Tag 
                  :value="getSubscriptionStatusLabel(selectedUser)"
                  :severity="getSubscriptionStatusSeverity(selectedUser)"
                  size="small"
                />
                <!-- Source badge for paid tiers -->
                <Tag 
                  v-if="selectedUser.subscription_tier !== 'free'"
                  :value="selectedUser.stripe_subscription_id ? ($t('admin.stripe') || 'Stripe') : ($t('admin.admin') || 'Admin')"
                  :severity="selectedUser.stripe_subscription_id ? 'info' : 'secondary'"
                  size="small"
                >
                  <template #icon>
                    <i :class="selectedUser.stripe_subscription_id ? 'pi pi-credit-card mr-1' : 'pi pi-shield mr-1'" style="font-size: 0.6rem;"></i>
                  </template>
                </Tag>
              </div>
              <!-- Current expiry info for existing subscriptions -->
              <div v-if="isEditingExistingSubscription" class="mt-2 pt-2 border-t border-slate-200">
                <div class="flex items-center gap-1.5 text-xs text-slate-600">
                  <i class="pi pi-calendar text-slate-400"></i>
                  <span>{{ $t('admin.current_expiry') || 'Current expiry' }}:</span>
                  <span class="font-medium text-slate-700">
                    {{ isPermanentSubscription(selectedUser.current_period_end) 
                      ? ($t('admin.permanent') || 'Permanent') 
                      : formatDate(selectedUser.current_period_end) }}
                  </span>
                  <span v-if="!isPermanentSubscription(selectedUser.current_period_end)" class="text-slate-400">
                    ({{ getDaysRemaining(selectedUser.current_period_end) }})
                  </span>
                </div>
              </div>
            </div>
          </div>
          
          <!-- Editing notice for existing subscriptions -->
          <div v-if="isEditingExistingSubscription && newSubscriptionTier === selectedUser.subscription_tier" 
            class="p-3 bg-blue-50 border border-blue-200 rounded-lg">
            <div class="flex items-start gap-2">
              <i class="pi pi-info-circle text-blue-600 mt-0.5"></i>
              <div class="text-sm text-blue-700">
                <p class="font-medium">{{ $t('admin.editing_existing_subscription') || 'Editing Existing Subscription' }}</p>
                <p class="mt-0.5 text-xs">{{ $t('admin.editing_existing_desc') || 'You are updating the duration for this user\'s existing subscription. The new expiry will be calculated from today.' }}</p>
              </div>
            </div>
          </div>

          <!-- Tier Selection -->
          <div>
            <label for="newTier" class="block text-sm font-medium text-slate-700 mb-2">
              {{ $t('admin.new_tier') || 'New Tier' }} <span class="text-red-500">*</span>
            </label>
            <div class="grid grid-cols-3 gap-2">
              <div 
                @click="newSubscriptionTier = 'free'"
                :class="[
                  'p-3 border-2 rounded-xl cursor-pointer transition-all duration-200',
                  newSubscriptionTier === 'free' 
                    ? 'border-slate-500 bg-slate-50' 
                    : 'border-slate-200 hover:border-slate-300'
                ]"
              >
                <div class="flex items-center gap-1.5 mb-1.5">
                  <i class="pi pi-user text-slate-600 text-sm"></i>
                  <span class="font-semibold text-slate-900 text-sm">{{ $t('subscription.free_plan') || 'Free' }}</span>
                </div>
                <ul class="text-[10px] text-slate-600 space-y-0.5 leading-tight">
                  <li>• {{ SubscriptionConfig.free.projectLimit }} {{ $t('admin.projects_label') || 'projects' }}</li>
                  <li>• {{ SubscriptionConfig.free.monthlyAccessLimit }} {{ $t('admin.access') || 'access' }}</li>
                </ul>
              </div>
              
              <div 
                @click="newSubscriptionTier = 'starter'"
                :class="[
                  'p-3 border-2 rounded-xl cursor-pointer transition-all duration-200',
                  newSubscriptionTier === 'starter' 
                    ? 'border-emerald-500 bg-emerald-50' 
                    : 'border-slate-200 hover:border-emerald-200'
                ]"
              >
                <div class="flex items-center gap-1.5 mb-1.5">
                  <i class="pi pi-bolt text-emerald-500 text-sm"></i>
                  <span class="font-semibold text-slate-900 text-sm">{{ $t('subscription.starter_plan') || 'Starter' }}</span>
                </div>
                <ul class="text-[10px] text-slate-600 space-y-0.5 leading-tight">
                  <li>• {{ SubscriptionConfig.starter.projectLimit }} {{ $t('admin.projects_label') || 'projects' }}</li>
                  <li>• ${{ SubscriptionConfig.starter.monthlyBudgetUsd }} {{ $t('admin.budget') || 'budget' }}</li>
                </ul>
              </div>

              <div
                @click="newSubscriptionTier = 'premium'"
                :class="[
                  'p-3 border-2 rounded-xl cursor-pointer transition-all duration-200',
                  newSubscriptionTier === 'premium'
                    ? 'border-amber-500 bg-amber-50'
                    : 'border-slate-200 hover:border-amber-200'
                ]"
              >
                <div class="flex items-center gap-1.5 mb-1.5">
                  <i class="pi pi-star-fill text-amber-500 text-sm"></i>
                  <span class="font-semibold text-slate-900 text-sm">{{ $t('subscription.premium_plan') || 'Premium' }}</span>
                </div>
                <ul class="text-[10px] text-slate-600 space-y-0.5 leading-tight">
                  <li>• {{ SubscriptionConfig.premium.projectLimit }} {{ $t('admin.projects_label') || 'projects' }}</li>
                  <li>• ${{ SubscriptionConfig.premium.monthlyBudgetUsd }} {{ $t('admin.budget') || 'budget' }}</li>
                </ul>
              </div>

              <div
                @click="newSubscriptionTier = 'enterprise'"
                :class="[
                  'p-3 border-2 rounded-xl cursor-pointer transition-all duration-200',
                  newSubscriptionTier === 'enterprise'
                    ? 'border-violet-500 bg-violet-50'
                    : 'border-slate-200 hover:border-violet-200'
                ]"
              >
                <div class="flex items-center gap-1.5 mb-1.5">
                  <i class="pi pi-building text-violet-500 text-sm"></i>
                  <span class="font-semibold text-slate-900 text-sm">{{ $t('subscription.enterprise_plan') || 'Enterprise' }}</span>
                </div>
                <ul class="text-[10px] text-slate-600 space-y-0.5 leading-tight">
                  <li>• {{ SubscriptionConfig.enterprise.projectLimit }} {{ $t('admin.projects_label') || 'projects' }}</li>
                  <li>• ${{ SubscriptionConfig.enterprise.monthlyBudgetUsd }} {{ $t('admin.budget') || 'budget' }}</li>
                </ul>
              </div>
            </div>
          </div>

          <!-- Duration Selection (only for paid tiers) -->
          <div v-if="newSubscriptionTier === 'starter' || newSubscriptionTier === 'premium' || newSubscriptionTier === 'enterprise'">
            <label class="block text-sm font-medium text-slate-700 mb-2">
              {{ $t('admin.subscription_duration') || 'Subscription Duration' }}
            </label>
            <div class="space-y-3">
              <!-- Duration Type -->
              <div class="flex gap-3">
                <div 
                  @click="subscriptionDurationType = 'permanent'"
                  :class="[
                    'flex-1 p-3 border-2 rounded-xl cursor-pointer transition-all duration-200 text-center',
                    subscriptionDurationType === 'permanent' 
                      ? 'border-blue-500 bg-blue-50' 
                      : 'border-slate-200 hover:border-blue-200'
                  ]"
                >
                  <div class="flex items-center justify-center gap-1.5">
                    <i class="pi pi-infinity text-blue-500 text-sm"></i>
                    <span class="font-medium text-slate-900 text-sm">{{ $t('admin.permanent') || 'Permanent' }}</span>
                  </div>
                  <p class="text-[10px] text-slate-500 mt-1">{{ $t('admin.no_expiration') || 'No expiration date' }}</p>
                </div>
                <div 
                  @click="subscriptionDurationType = 'months'"
                  :class="[
                    'flex-1 p-3 border-2 rounded-xl cursor-pointer transition-all duration-200 text-center',
                    subscriptionDurationType === 'months' 
                      ? 'border-blue-500 bg-blue-50' 
                      : 'border-slate-200 hover:border-blue-200'
                  ]"
                >
                  <div class="flex items-center justify-center gap-1.5">
                    <i class="pi pi-calendar text-blue-500 text-sm"></i>
                    <span class="font-medium text-slate-900 text-sm">{{ $t('admin.specific_duration') || 'Specific Duration' }}</span>
                  </div>
                  <p class="text-[10px] text-slate-500 mt-1">{{ $t('admin.set_months') || 'Set number of months' }}</p>
                </div>
              </div>
              
              <!-- Months Input (shown when specific duration selected) -->
              <div v-if="subscriptionDurationType === 'months'" class="space-y-2">
                <div class="flex items-center gap-3">
                  <InputNumber 
                    v-model="subscriptionDurationMonths"
                    :min="1"
                    :max="120"
                    showButtons
                    buttonLayout="horizontal"
                    :step="1"
                    class="w-32"
                    inputClass="text-center font-medium"
                  >
                    <template #incrementicon>
                      <i class="pi pi-plus text-xs"></i>
                    </template>
                    <template #decrementicon>
                      <i class="pi pi-minus text-xs"></i>
                    </template>
                  </InputNumber>
                  <span class="text-sm text-slate-600">{{ $t('admin.months') || 'months' }}</span>
                </div>
                <div class="flex items-center gap-1.5 text-xs text-slate-500">
                  <i class="pi pi-calendar text-slate-400"></i>
                  <span>{{ $t('admin.expires_on') || 'Expires on' }}: <strong class="text-slate-700">{{ getExpirationDate() }}</strong></span>
                </div>
              </div>
            </div>
          </div>

          <!-- Reason -->
          <div>
            <label for="subscriptionReason" class="block text-sm font-medium text-slate-700 mb-2">
              {{ $t('admin.reason_for_change') || 'Reason for Change' }} <span class="text-red-500">*</span>
            </label>
            <Textarea 
              id="subscriptionReason"
              v-model="subscriptionChangeReason"
              rows="3"
              :placeholder="$t('admin.subscription_reason_placeholder') || 'Explain why this subscription change is necessary (e.g., promotional upgrade, support case, etc.)'"
              class="w-full"
            />
          </div>

          <!-- Block for Stripe-managed subscriptions (mutually exclusive) -->
          <div v-if="selectedUser.stripe_subscription_id" class="p-3 bg-red-50 border border-red-200 rounded-lg">
            <div class="flex items-start gap-2">
              <i class="pi pi-ban text-red-600 mt-0.5"></i>
              <div class="text-sm text-red-700">
                <p class="font-medium">{{ $t('admin.stripe_block_title') || 'Cannot Modify: Stripe Subscription Active' }}</p>
                <p class="mt-1">
                  {{ $t('admin.stripe_block_desc') || 'Admin grants and Stripe subscriptions are mutually exclusive. To grant admin privilege:' }}
                </p>
                <ol class="mt-1.5 ml-4 list-decimal text-xs space-y-1">
                  <li>{{ $t('admin.stripe_block_step1') || 'Go to Stripe Dashboard' }}</li>
                  <li>{{ $t('admin.stripe_block_step2') || 'Cancel this user\'s subscription' }}</li>
                  <li>{{ $t('admin.stripe_block_step3') || 'Return here to grant admin privilege' }}</li>
                </ol>
                <p class="mt-2 text-xs text-red-600 font-medium">
                  <i class="pi pi-info-circle mr-1"></i>
                  {{ $t('admin.stripe_block_id') || 'Stripe Subscription ID' }}: 
                  <code class="bg-red-100 px-1 rounded">{{ selectedUser.stripe_subscription_id }}</code>
                </p>
              </div>
            </div>
          </div>
        </div>

        <template #footer>
          <Button :label="$t('common.cancel')" text severity="secondary" @click="closeSubscriptionDialog" />
          <Button 
            :label="$t('admin.update_subscription') || 'Update Subscription'" 
            :severity="newSubscriptionTier === 'enterprise' ? 'contrast' : newSubscriptionTier === 'premium' ? 'warning' : 'primary'"
            @click="updateUserSubscription"
            :disabled="!newSubscriptionTier || !subscriptionChangeReason || (newSubscriptionTier === 'free' && selectedUser?.subscription_tier === 'free') || selectedUser?.stripe_subscription_id"
            :loading="isUpdatingSubscription"
          >
            <template #icon>
              <i :class="newSubscriptionTier === 'enterprise' ? 'pi pi-building mr-2' : newSubscriptionTier === 'premium' ? 'pi pi-star-fill mr-2' : 'pi pi-user mr-2'"></i>
            </template>
          </Button>
        </template>
      </Dialog>
      <!-- User Projects Dialog -->
      <Dialog
        v-model:visible="showUserProjectsDialog"
        modal
        :header="userProjectsDialogTitle"
        :style="{ width: '95vw', maxWidth: '120rem' }"
        @hide="closeUserProjectsDialog"
      >
        <!-- User Info Bar -->
        <div v-if="projectsUser" class="mb-4 p-3 bg-slate-50 border border-slate-200 rounded-lg flex items-center gap-3">
          <div class="w-8 h-8 bg-gradient-to-r from-blue-500 to-indigo-500 rounded-full flex items-center justify-center text-white text-xs font-medium flex-shrink-0">
            {{ projectsUser.user_email.charAt(0).toUpperCase() }}
          </div>
          <div>
            <p class="font-medium text-slate-900 text-sm">{{ projectsUser.user_email }}</p>
            <div class="flex items-center gap-2 mt-0.5">
              <Tag :value="getTierLabel(projectsUser.subscription_tier)" :severity="getTierSeverity(projectsUser.subscription_tier)" size="small" />
              <span class="text-xs text-slate-400 flex items-center gap-1"><i class="pi pi-eye text-[10px]"></i> {{ $t('admin.read_only_view') }}</span>
            </div>
          </div>
          <div class="ml-auto text-center px-3 py-1 bg-white rounded-lg border border-slate-200">
            <p class="text-lg font-bold text-slate-900">{{ adminUserCardsStore.userCards.length }}</p>
            <p class="text-[10px] text-slate-500 uppercase">{{ $t('admin.projects') }}</p>
          </div>
        </div>

        <!-- Error state -->
        <div v-if="adminUserCardsStore.error && !adminUserCardsStore.isLoadingCards" class="p-4 bg-red-50 border border-red-200 rounded-lg mb-4">
          <div class="flex items-center gap-2 text-red-700">
            <i class="pi pi-exclamation-circle"></i>
            <span>{{ adminUserCardsStore.error }}</span>
          </div>
        </div>

        <!-- Two-panel layout -->
        <div class="grid grid-cols-1 lg:grid-cols-4 gap-4" style="min-height: 60vh;">
          <div class="lg:col-span-1">
            <AdminCardListPanel
              :cards="adminUserCardsStore.userCards"
              :selectedCardId="projectsSelectedCardId"
              :isLoading="adminUserCardsStore.isLoadingCards"
              @select-card="handleProjectsSelectCard"
            />
          </div>
          <div class="lg:col-span-3">
            <AdminCardDetailPanel
              :selectedCard="projectsSelectedCard as any"
              :content="adminUserCardsStore.selectedCardContent as any"
              :isLoadingContent="adminUserCardsStore.isLoadingContent"
              v-model:activeTab="projectsActiveTabString"
            />
          </div>
        </div>
      </Dialog>
    </div>
  </PageWrapper>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { supabase } from '@/lib/supabase'
import { useToast } from 'primevue/usetoast'
import { storeToRefs } from 'pinia'
import Button from 'primevue/button'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import Dialog from 'primevue/dialog'
import InputText from 'primevue/inputtext'
import InputIcon from 'primevue/inputicon'
import IconField from 'primevue/iconfield'
import Select from 'primevue/select'
import Tag from 'primevue/tag'
import Textarea from 'primevue/textarea'
import InputNumber from 'primevue/inputnumber'
import PageWrapper from '@/components/Layout/PageWrapper.vue'
import AdminCardListPanel from '@/components/Admin/AdminCardListPanel.vue'
import AdminCardDetailPanel from '@/components/Admin/AdminCardDetailPanel.vue'
import { useAdminUserCardsStore } from '@/stores/admin/userCards'
import { SubscriptionConfig } from '@/config/subscription'
import { formatDate } from '@/utils/formatters'

const { t } = useI18n()
const toast = useToast()
const adminUserCardsStore = useAdminUserCardsStore()

// State
const isLoading = ref(false)
const allUsers = ref([])
const filteredUsers = ref([])
const searchQuery = ref('')
const selectedRole = ref(null)
const selectedTier = ref(null)
const currentPage = ref(0)
const pageSize = ref(20)

// Dialog state - Role
const showRoleDialog = ref(false)
const selectedUser = ref(null)
const newUserRole = ref('')
const roleChangeReason = ref('')

// Dialog state - Subscription
const showSubscriptionDialog = ref(false)
const newSubscriptionTier = ref('')
const subscriptionChangeReason = ref('')
const isUpdatingSubscription = ref(false)
const subscriptionDurationType = ref('permanent') // 'permanent' or 'months'
const subscriptionDurationMonths = ref(12) // Default 12 months

// Dialog state - User Projects
const showUserProjectsDialog = ref(false)
const projectsUser = ref(null)
const projectsSelectedCardId = ref(null)
const projectsActiveTab = ref(0)

const projectsActiveTabString = computed({
  get: () => projectsActiveTab.value.toString(),
  set: (value) => { projectsActiveTab.value = parseInt(value) }
})

const userProjectsDialogTitle = computed(() => {
  if (!projectsUser.value) return t('admin.user_projects') || 'User Projects'
  return `${t('admin.projects_for') || 'Projects for'} ${projectsUser.value.user_email}`
})

const projectsSelectedCard = computed(() => {
  if (!projectsSelectedCardId.value) return null
  const card = adminUserCardsStore.userCards.find(c => c.id === projectsSelectedCardId.value)
  if (!card) return null
  return {
    ...card,
    user_id: projectsUser.value?.user_id || '',
    description: card.description || '',
    ai_instruction: card.ai_instruction || '',
    ai_knowledge_base: card.ai_knowledge_base || ''
  }
})

// Computed: Check if editing existing paid subscription
const isEditingExistingSubscription = computed(() => {
  return selectedUser.value && 
    selectedUser.value.subscription_tier !== 'free' && 
    selectedUser.value.current_period_end
})

// Computed
const userStats = computed(() => {
  const total = allUsers.value.length
  const cardIssuers = allUsers.value.filter(u => u.role === 'cardIssuer' || u.role === 'card_issuer').length
  const admins = allUsers.value.filter(u => u.role === 'admin').length
  const premiumUsers = allUsers.value.filter(u => u.subscription_tier === 'premium').length
  const starterUsers = allUsers.value.filter(u => u.subscription_tier === 'starter').length
  const enterpriseUsers = allUsers.value.filter(u => u.subscription_tier === 'enterprise').length
  const freeUsers = total - premiumUsers - starterUsers - enterpriseUsers

  return {
    total,
    cardIssuers,
    admins,
    premiumUsers,
    starterUsers,
    enterpriseUsers,
    freeUsers
  }
})

const paginatedUsers = computed(() => {
  const start = currentPage.value * pageSize.value
  const end = start + pageSize.value
  return filteredUsers.value.slice(start, end)
})

const hasActiveFilters = computed(() => {
  return searchQuery.value || selectedRole.value || selectedTier.value
})

// Options
const roleOptions = computed(() => [
  { label: t('admin.all_roles'), value: null },
  { label: t('common.card_issuer'), value: 'cardIssuer' },
  { label: t('common.admin'), value: 'admin' },
  { label: t('admin.user'), value: 'user' }
])

const roleChangeOptions = computed(() => [
  { label: t('common.card_issuer'), value: 'cardIssuer' },
  { label: t('common.admin'), value: 'admin' },
  { label: t('admin.user'), value: 'user' }
])

const tierOptions = computed(() => [
  { label: t('admin.all_tiers') || 'All Tiers', value: null },
  { label: t('subscription.enterprise_plan') || 'Enterprise', value: 'enterprise' },
  { label: t('subscription.premium_plan') || 'Premium', value: 'premium' },
  { label: t('subscription.starter_plan') || 'Starter', value: 'starter' },
  { label: t('subscription.free_plan') || 'Free', value: 'free' }
])

// Methods
const loadUsers = async () => {
  isLoading.value = true
  try {
    const { data, error } = await supabase.rpc('admin_get_all_users')
    if (error) throw error
    
    allUsers.value = data || []
    filterUsers()
  } catch (error) {
    console.error('Error loading users:', error)
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: t('admin.failed_to_load_users'),
      life: 3000
    })
  } finally {
    isLoading.value = false
  }
}

const filterUsers = () => {
  let filtered = [...allUsers.value]

  // Search filter
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    filtered = filtered.filter(user =>
      user.user_email?.toLowerCase().includes(query)
    )
  }

  // Role filter
  if (selectedRole.value) {
    filtered = filtered.filter(user => user.role === selectedRole.value)
  }

  // Tier filter
  if (selectedTier.value) {
    filtered = filtered.filter(user => user.subscription_tier === selectedTier.value)
  }

  filteredUsers.value = filtered
  currentPage.value = 0 // Reset to first page
}

const clearFilters = () => {
  searchQuery.value = ''
  selectedRole.value = null
  selectedTier.value = null
  filterUsers()
}

const refreshData = () => {
  loadUsers()
}

const onPageChange = (event) => {
  currentPage.value = event.page
  pageSize.value = event.rows
}

const exportUsers = () => {
  const csvData = filteredUsers.value.map(user => ({
    Email: user.user_email,
    Role: user.role || 'cardIssuer',
    'Subscription Tier': user.subscription_tier || 'free',
    'Subscription Status': user.subscription_status || 'active',
    'Cards Count': user.cards_count || 0,
    'Created Date': formatDate(user.created_at),
    'Last Sign In': user.last_sign_in_at ? formatDate(user.last_sign_in_at) : 'Never',
    'Stripe Subscription ID': user.stripe_subscription_id || '',
    'Period End': user.current_period_end ? formatDate(user.current_period_end) : ''
  }))

  if (!csvData.length) return

  const csv = [
    Object.keys(csvData[0]).join(','),
    ...csvData.map(row => Object.values(row).map(val => `"${val}"`).join(','))
  ].join('\n')

  const blob = new Blob([csv], { type: 'text/csv' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `users-export-${new Date().toISOString().split('T')[0]}.csv`
  a.click()
  URL.revokeObjectURL(url)
}

const manageUserRole = (user) => {
  selectedUser.value = user
  newUserRole.value = user.role || 'cardIssuer'
  roleChangeReason.value = ''
  showRoleDialog.value = true
}

const closeRoleDialog = () => {
  selectedUser.value = null
  newUserRole.value = ''
  roleChangeReason.value = ''
  showRoleDialog.value = false
}

const updateUserRole = async () => {
  if (!selectedUser.value || !newUserRole.value || !roleChangeReason.value) return

  try {
    const { error } = await supabase.rpc('admin_update_user_role', {
      p_user_id: selectedUser.value.user_id,
      p_new_role: newUserRole.value,
      p_reason: roleChangeReason.value
    })

    if (error) throw error

    toast.add({
      severity: 'success',
      summary: t('common.success'),
      detail: t('admin.user_role_updated_successfully'),
      life: 3000
    })

    closeRoleDialog()
    await refreshData()
  } catch (error) {
    console.error('Error updating user role:', error)
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: t('admin.failed_to_update_user_role'),
      life: 3000
    })
  }
}

// Subscription management methods
const manageUserSubscription = (user) => {
  selectedUser.value = user
  newSubscriptionTier.value = user.subscription_tier || 'free'
  subscriptionChangeReason.value = ''
  
  // Pre-fill duration based on current subscription
  if (user.subscription_tier !== 'free' && user.current_period_end) {
    const periodEnd = new Date(user.current_period_end)
    const now = new Date()
    const yearsFromNow = (periodEnd.getTime() - now.getTime()) / (1000 * 60 * 60 * 24 * 365)
    
    if (yearsFromNow > 50) {
      // Permanent subscription
      subscriptionDurationType.value = 'permanent'
      subscriptionDurationMonths.value = 12
    } else {
      // Calculate remaining months
      const monthsRemaining = Math.max(1, Math.round((periodEnd.getTime() - now.getTime()) / (1000 * 60 * 60 * 24 * 30)))
      subscriptionDurationType.value = 'months'
      subscriptionDurationMonths.value = monthsRemaining
    }
  } else {
    subscriptionDurationType.value = 'permanent'
    subscriptionDurationMonths.value = 12
  }
  
  showSubscriptionDialog.value = true
}

const closeSubscriptionDialog = () => {
  selectedUser.value = null
  newSubscriptionTier.value = ''
  subscriptionChangeReason.value = ''
  subscriptionDurationType.value = 'permanent'
  subscriptionDurationMonths.value = 12
  showSubscriptionDialog.value = false
}

const updateUserSubscription = async () => {
  if (!selectedUser.value || !newSubscriptionTier.value || !subscriptionChangeReason.value) return
  // Only block if updating Free to Free (no changes possible)
  if (newSubscriptionTier.value === 'free' && selectedUser.value.subscription_tier === 'free') return

  isUpdatingSubscription.value = true
  
  // Calculate duration: null for permanent or free tier, number for specific months
  const durationMonths = (newSubscriptionTier.value === 'free' || subscriptionDurationType.value === 'permanent') 
    ? null 
    : subscriptionDurationMonths.value
  
  try {
    const { error } = await supabase.rpc('admin_update_user_subscription', {
      p_user_id: selectedUser.value.user_id,
      p_new_tier: newSubscriptionTier.value,
      p_reason: subscriptionChangeReason.value,
      p_duration_months: durationMonths
    })

    if (error) throw error

    toast.add({
      severity: 'success',
      summary: t('common.success'),
      detail: t('admin.subscription_updated_successfully') || 'Subscription updated successfully',
      life: 3000
    })

    closeSubscriptionDialog()
    await refreshData()
  } catch (error) {
    console.error('Error updating user subscription:', error)
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: t('admin.failed_to_update_subscription') || 'Failed to update subscription',
      life: 3000
    })
  } finally {
    isUpdatingSubscription.value = false
  }
}

// Helper functions
const getRoleLabel = (role) => {
  if (role === 'cardIssuer' || role === 'card_issuer') return t('common.card_issuer')
  if (role === 'admin') return t('common.admin')
  return t('admin.user')
}

const getRoleSeverity = (role) => {
  if (role === 'admin') return 'danger'
  if (role === 'cardIssuer' || role === 'card_issuer') return 'success'
  return 'secondary'
}

const getTierLabel = (tier) => {
  if (tier === 'enterprise') return t('subscription.enterprise_plan') || 'Enterprise'
  if (tier === 'premium') return t('subscription.premium_plan') || 'Premium'
  if (tier === 'starter') return t('subscription.starter_plan') || 'Starter'
  return t('subscription.free_plan') || 'Free'
}

const getTierSeverity = (tier) => {
  if (tier === 'enterprise') return 'contrast'
  if (tier === 'premium') return 'warning'
  if (tier === 'starter') return 'success'
  return 'secondary'
}

const getSubscriptionStatusLabel = (user) => {
  if (!user) return 'Active'
  
  if (user.cancel_at_period_end) {
    return t('admin.canceling') || 'Canceling'
  }
  
  const status = user.subscription_status || 'active'
  switch (status) {
    case 'active': return t('common.active') || 'Active'
    case 'past_due': return t('admin.past_due') || 'Past Due'
    case 'canceled': return t('admin.canceled') || 'Canceled'
    case 'trialing': return t('admin.trialing') || 'Trialing'
    default: return status
  }
}

const getSubscriptionStatusSeverity = (user) => {
  if (!user) return 'success'
  
  if (user.cancel_at_period_end) return 'warning'
  
  const status = user.subscription_status || 'active'
  switch (status) {
    case 'active': return 'success'
    case 'past_due': return 'danger'
    case 'canceled': return 'secondary'
    case 'trialing': return 'info'
    default: return 'secondary'
  }
}

const getExpirationDate = () => {
  const date = new Date()
  date.setMonth(date.getMonth() + subscriptionDurationMonths.value)
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  })
}

const isPermanentSubscription = (dateString) => {
  if (!dateString) return false
  const date = new Date(dateString)
  const now = new Date()
  // If expiration is more than 50 years from now, consider it permanent
  const yearsFromNow = (date.getTime() - now.getTime()) / (1000 * 60 * 60 * 24 * 365)
  return yearsFromNow > 50
}

const getDaysRemaining = (dateString) => {
  if (!dateString) return ''
  const date = new Date(dateString)
  const now = new Date()
  const diffTime = date.getTime() - now.getTime()
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
  
  if (diffDays < 0) {
    return t('admin.expired') || 'Expired'
  } else if (diffDays === 0) {
    return t('admin.expires_today') || 'Expires today'
  } else if (diffDays === 1) {
    return t('admin.expires_tomorrow') || 'Expires tomorrow'
  } else if (diffDays <= 30) {
    return (t('admin.days_remaining') || '{days} days remaining').replace('{days}', diffDays)
  } else {
    const months = Math.floor(diffDays / 30)
    return (t('admin.months_remaining') || '{months} months remaining').replace('{months}', months)
  }
}

// User Projects methods
const viewUserProjects = async (user) => {
  projectsUser.value = user
  projectsSelectedCardId.value = null
  projectsActiveTab.value = 0
  adminUserCardsStore.clearCurrentUser()
  showUserProjectsDialog.value = true

  try {
    await adminUserCardsStore.fetchUserCards(user.user_id)
  } catch (err) {
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: t('admin.failed_to_load_user_projects') || 'Failed to load user projects',
      life: 3000
    })
  }
}

const closeUserProjectsDialog = () => {
  showUserProjectsDialog.value = false
  projectsUser.value = null
  projectsSelectedCardId.value = null
  projectsActiveTab.value = 0
  adminUserCardsStore.clearCurrentUser()
}

const handleProjectsSelectCard = async (cardId) => {
  projectsSelectedCardId.value = cardId
  projectsActiveTab.value = 0
  try {
    await adminUserCardsStore.fetchCardContent(cardId)
  } catch (err) {
    toast.add({
      severity: 'error',
      summary: t('messages.load_failed'),
      detail: t('messages.failed_to_load_card_details'),
      life: 3000
    })
  }
}

// Lifecycle
onMounted(() => {
  loadUsers()
})
</script>

<style scoped>
:deep(.users-table) {
  font-size: 0.875rem;
}

:deep(.users-table .p-datatable-thead > tr > th) {
  background-color: #f8fafc;
  color: #475569;
  font-weight: 600;
  font-size: 0.875rem;
  padding: 0.75rem 1rem;
  white-space: nowrap;
}

:deep(.users-table .p-datatable-tbody > tr > td) {
  padding: 0.75rem 1rem;
  vertical-align: middle;
}

:deep(.users-table .p-datatable-tbody > tr:hover) {
  background-color: #f8fafc;
}

/* Frozen columns styling */
:deep(.users-table .p-frozen-column) {
  background-color: white;
  z-index: 1;
}

:deep(.users-table .p-datatable-thead .p-frozen-column) {
  background-color: #f8fafc;
}

/* Scrollable table wrapper */
:deep(.users-table .p-datatable-wrapper) {
  overflow-x: auto;
}

/* Responsive adjustments for smaller screens */
@media (max-width: 768px) {
  :deep(.users-table .p-datatable-thead > tr > th) {
    padding: 0.5rem 0.75rem;
    font-size: 0.75rem;
  }
  
  :deep(.users-table .p-datatable-tbody > tr > td) {
    padding: 0.5rem 0.75rem;
  }
}

/* Table container max height */
:deep(.users-table .p-datatable-scrollable-body) {
  max-height: calc(100vh - 400px);
  min-height: 400px;
}
</style>
