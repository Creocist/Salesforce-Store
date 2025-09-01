import { LightningElement,api, wire, track } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import searchItems from '@salesforce/apex/ItemClass.searchItems';
import ItemsWithImages from '@salesforce/apex/GetImageItem.ItemsWithImages';
import checkout from '@salesforce/apex/CheckoutController.checkout';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Picklists
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import ITEM_OBJECT from '@salesforce/schema/Item__c';
import TYPE_FIELD from '@salesforce/schema/Item__c.Type__c';
import FAMILY_FIELD from '@salesforce/schema/Item__c.Family__c';

//User
import USER_ID from '@salesforce/user/Id';
import IS_MANAGER_FIELD from '@salesforce/schema/User.IsManager__c';

// Account header
import NAME_FIELD from '@salesforce/schema/Account.Name';
import NUMBER_FIELD from '@salesforce/schema/Account.AccountNumber';
import INDUSTRY_FIELD from '@salesforce/schema/Account.Industry';
export default class ItemCatalog extends NavigationMixin(LightningElement) {
    //Account
    accountId;
    // State
    items = [];
    searchKey = '';
    selectedTypes = [];
    selectedFamilies = [];
    limitSize = 24;
    offsetSize = 0;
    isManager = false;

    // Cart
    @track cart = [];
    cartOpen = false;
    isCheckingOut = false;


    // Details modal
    detailsId;


    // --- User
    @wire(getRecord, { recordId: USER_ID, fields: [IS_MANAGER_FIELD] })
    wiredUser({ error, data }) {
        if (data) {
            this.isManager = data.fields.IsManager__c.value;
        } else if (error) {
            console.error('Error loading user data', error);
        }
    }

    // --- Picklists

    @wire(getObjectInfo, { objectApiName: ITEM_OBJECT }) objectInfo;
    get recordTypeId() {
        return this.objectInfo?.data?.defaultRecordTypeId || null;
    }
    typeOptions = [];
    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: TYPE_FIELD })
    wiredTypes({ data }) {
        if (data) this.typeOptions = data.values.map(v => ({ label: v.label, value: v.value }));
    }

    familyOptions = [];
    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: FAMILY_FIELD })
    wiredFamilies({ data }) {
        if (data) this.familyOptions = data.values.map(v => ({ label: v.label, value: v.value }));
    }
    // --- Adding Image

    // --- Account header
    @wire(CurrentPageReference)
    getPageRef(pageRef) {
        if (pageRef && pageRef.state && pageRef.state.c__accountId) {
            this.accountId = pageRef.state.c__accountId;
        }
    }
    @wire(getRecord, { recordId: '$accountId', fields: [NAME_FIELD, NUMBER_FIELD, INDUSTRY_FIELD] })
    account;
    get accountName() {
        return getFieldValue(this.account.data, NAME_FIELD);
    }
    get accountNumber() {
        return getFieldValue(this.account.data, NUMBER_FIELD);
    }
    get accountIndustry() {
        return getFieldValue(this.account.data, INDUSTRY_FIELD);
    }

    // --- Lifecycle
    connectedCallback() {
        this.fetchItems();
        ItemsWithImages()
            .then(() => {
                console.log('Images updated successfully');
                this.fetchItems();
            })
            .catch(error => {
                console.error('Error updating images', error);
            });
    }
    get cartCount() {
        return this.cart.reduce((sum, i) => sum + i.qty, 0);
    }
    get cartLabel() {
        return this.cartCount ? `Cart (${this.cartCount})` : 'Cart';
    }
    get detailsItem() {
        return this.items.find(i => i.Id === this.detailsId);
    }

    // --- Events
    handleSearchChange(e) {
        this.searchKey = e.target.value;
        this.offsetSize = 0;
        this.fetchItemsDebounced();
    }
    handleTypeChange(e) {
        this.selectedTypes = e.detail.value;
        this.offsetSize = 0;
        this.fetchItems();
    }
    handleFamilyChange(e) {
        this.selectedFamilies = e.detail.value;
        this.offsetSize = 0;
        this.fetchItems();
    }

    _debounce;
    fetchItemsDebounced() {
        clearTimeout(this._debounce);
        this._debounce = setTimeout(() => this.fetchItems(), 300);
    }

    fetchItems() {
        searchItems({
            types: this.selectedTypes,
            families: this.selectedFamilies,
            searchKey: this.searchKey,
            limitSize: this.limitSize,
            offsetSize: this.offsetSize
        })
        .then(res => { this.items = res; })
        .catch(err => { console.error(err); this.items = []; });
    }

    // Details
    openDetails = (e) => { this.detailsId = e.currentTarget.dataset.id; };
    closeDetails = () => { this.detailsId = undefined; };

    // Cart controls
    handleAddToCart = (e) => {
        const id = e.currentTarget.dataset.id;
        const found = this.items.find(i => i.Id === id);
        if (!found) return;
        const existing = this.cart.find(c => c.Id === id);
        if (existing) { existing.qty += 1; this.cart = [...this.cart]; }
        else { this.cart = [...this.cart, { ...found, qty: 1 }]; }
    };
    toggleCart = () => { this.cartOpen = !this.cartOpen; };
    incQty = (e) => {
        const id = e.currentTarget.dataset.id;
        const it = this.cart.find(c => c.Id === id);
        if (it) { it.qty += 1; this.cart = [...this.cart]; }
    };
    decQty = (e) => {
        const id = e.currentTarget.dataset.id;
        const idx = this.cart.findIndex(c => c.Id === id);
        if (idx > -1) {
            this.cart[idx].qty -= 1;
            if (this.cart[idx].qty <= 0) this.cart.splice(idx, 1);
            this.cart = [...this.cart];
        }
    };
    //Checkout
    async handleCheckout() {
        if (!this.accountId) {
            this.showToast('Error', 'Account not provided.', 'error');
            return;
        }
        if (!this.cart || this.cart.length === 0) {
            this.showToast('Info', 'Cart is empty.', 'info');
            return;
        }
        if (this.isCheckingOut) return;

        this.isCheckingOut = true;
        try {
            const lines = this.cart.map(c => ({
                itemId: String(c.Id),
                qty: parseInt(c.qty, 10)
            }));

            console.log( JSON.stringify({ accountId: this.accountId, lines }));
            const purchaseId = await checkout({
                accountId: this.accountId,
                lines: lines
            });

            this.cart = [];
            this.showToast('Success', 'Purchase created', 'success');

            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: purchaseId,
                    objectApiName: 'Purchase__c',
                    actionName: 'view'
                }
            });
        } catch (err) {
            console.error('Checkout error', err);
            this.showToast('Checkout failed', this.extractErrorMessage(err), 'error');
        } finally {
            this.isCheckingOut = false;
        }
    }
    showToast(title, message, variant = 'info') {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    // Create Item
    handleCreateItem() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Item__c',
                actionName: 'new'
            }
        });
    }

    extractErrorMessage(error) {
        if (!error) return 'Unknown error';
        if (error.body && error.body.message) return error.body.message;
        return (error.message) ? error.message : JSON.stringify(error);
    }
}