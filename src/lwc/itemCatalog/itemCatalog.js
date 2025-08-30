import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import searchItems from '@salesforce/apex/ItemClass.searchItems';


// Picklists via UI API
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import ITEM_OBJECT from '@salesforce/schema/Item__c';
import TYPE_FIELD from '@salesforce/schema/Item__c.Type__c';
import FAMILY_FIELD from '@salesforce/schema/Item__c.Family__c';

//User
import USER_ID from '@salesforce/user/Id';
import IS_MANAGER_FIELD from '@salesforce/schema/User.IsManager__c';

// Account header (if on Account record page)
import { getRecord } from 'lightning/uiRecordApi';
import ACCOUNT_NAME from '@salesforce/schema/Account.Name';
import ACCOUNT_NUMBER from '@salesforce/schema/Account.AccountNumber';
import ACCOUNT_INDUSTRY from '@salesforce/schema/Account.Industry';

export default class ItemCatalog extends NavigationMixin(LightningElement) {
    @api recordId;

    // State
    items = [];
    searchKey = '';
    selectedTypes = [];
    selectedFamilies = [];
    limitSize = 24;
    offsetSize = 0;
    isManager = false;

    // Cart
    cart = [];
    cartOpen = false;

    // Details modal
    detailsId;


    //User
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

    // --- Account header
    @wire(getRecord, { recordId: '$recordId', fields: [ACCOUNT_NAME, ACCOUNT_NUMBER, ACCOUNT_INDUSTRY] })
    account;

    get accountName()     { return this.account?.data?.fields?.Name?.value; }
    get accountNumber()   { return this.account?.data?.fields?.AccountNumber?.value; }
    get accountIndustry() { return this.account?.data?.fields?.Industry?.value; }

    // --- Lifecycle
    connectedCallback() {
        this.fetchItems(); // initial load (no filters)
    }

    // --- UI computed
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

    // Images placeholder
    handleImgError(event) {
        event.target.src = 'https://via.placeholder.com/600x400?text=No+Image';
    }

    // Details modal
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

    // Create Item (standard new-record page)
    handleCreateItem() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Item__c',
                actionName: 'new'
            }
        });
    }
}